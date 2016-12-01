/*Copyright (C) 2012 Hannes Maier-Flaig

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/* 
This is a simple script that is intended to be used with the tinkerforge
stepper brick and the IO4 bricklet. See README.md for more information.

  Purpose of the setup is to let a stepper motor advance a certain amount
of steps everytime a TTL pulse is registered at pin 0 of the IO4 bricklet.
In addition to that the current position is registered as No. of steps and
angle (using a specified gear ratio). Furthermore, one can set and return
to a "home" position.

  This (and some mechanical parts) form an automatic goinometer for an EPR-
spectrometer.

ROADMAP:
  + Record positions for every TTL pulse in sensible, simple file format
  + Add commandline parameters to set gear ratio, step size...
  + Use sensible folder structure and improve makefile
  + Use time of TTL pulse to determine step width
  + Regain platform independance (move away from ncurses)
  o Use position of stepper provided by bricklet to go home
  o Move configuration variables to config file
  o Add and LCD, pysical buttons for home and step size and implement a 
    stand-alone solution (maybe)
  o check for integer overflows on interrupts (unlikely to occur but who 
    knows)
*/

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <time.h>
#include <math.h>
#ifdef __unix__
# include <unistd.h>
#elif defined _WIN32 /* Win 32 & 64 bit */
# include <windows.h>
#endif


#include "ip_connection.h"
#include "bricklet_io4.h"
#include "brick_stepper.h"

#define HOST "localhost"
#define PORT 4223
#define IO4_UID "7QU" // IO4 UID
#define STEPPER_UID "94ANaVvVWoE" // Stepper UID

Stepper stepper;
IO4 io;

FILE *logfile;

int nSteps = 0;         // number of performed steps since last home position
int nStepsPerInterrupt; // default is set to an equivalent of 5deg when parsing arguments
float gear_ratio = 3;   // gear ratio > 1 means motor gear has less teeth
float steps_per_revolution = 200;  // 200 -> 1 full step = 1.8 deg
int step_mode = 8;	// perform 1/1,1/2,1/4 or 1/8 steps. 1/8 is highest precission but lowest torque
int sweep_time = 0; // sweep time of the experiment in seconds (used for -t)
int n_aquisitions = 0;
    
int dynamic_flag, no_record_flag, triggered_flag;
int last_value_mask;
int last_interrupt_time_pin0 = 0;
bool position_reached = false;


int angle2steps(float angle) {
    int steps = floor(angle * steps_per_revolution / 360. * step_mode * gear_ratio + 0.5);

    return steps;
}


float steps2angle(int steps) {
    float angle = steps / steps_per_revolution * 360 / step_mode / gear_ratio;
        
    return angle;
}


void print_stats(int nSteps) {
    char strTime[80];
    time_t t;
    struct tm *ts;


    t = time(NULL);
    ts = localtime(&t);
    strftime(strTime, 80, "%Y/%m/%d %H:%M", ts);

    printf("\rPosition: %6.2fdeg (%3d steps)", steps2angle(nSteps), nSteps);
    if( ! no_record_flag) {
      fprintf(logfile, "[%s] %6.2fdeg\n", strTime, steps2angle(nSteps));
    }
    fflush(stdout);
}


void display_usage() {
    printf("This program drives a stepper motor when a TTL pulse is registered on port 0 of a tinkerforge IO4 bricklet.\n\n");
    printf("Command line arguments:\n");
    printf("    -a,  --angle       Angle by wich motor advances on interrupt (default: 5)\n");
    printf("    -g,  --gear-ratio  Gear ratio between motor and sample rod (default: 2)\n");
    printf("    -s,  --steps-per-revolution Number of full-width steps needed for one revolution of the motor rod (default:200)\n");
    printf("    -m,  --step-mode   Perform 1/n steps. Note 1/1 steps give the biggest torque. (n = (1,2,4,8); default: 1)\n");
    printf("    -d,  --dynamic     Dynamic mode: --angle is ignored and instead TTL pulse length is used. 10ms = 0.1deg\n");
    printf("    -r,  --no-record   Do not keep a logfile that records every angle\n");
    printf("    -t,  --trigger     Trigger spectrometer instead of being triggered by it (for CW measurements)\n");
    printf("    -w,  --sweep-time  Time spectrometer needs for field sweep and to ready for the next one (with -t)\n");
    printf("    -n,  --n-aquisitions  Number of field sweeps/aquisitions (with -t)\n");

}


bool is_motor_ready() {
    int32_t rem_steps = 0;
    stepper_get_remaining_steps(&stepper, &rem_steps);
    if(rem_steps != 0) {
        //printf("\rInterrupt request ignored because motor was still running\n");
        //print_stats(nSteps);
        return false;
    } else {
        return true;
    }
}


void advance(int steps) {
    if( ! is_motor_ready())
      return;
    
    position_reached = false;
      
    stepper_set_steps(&stepper, steps);
    nSteps += steps;
    
    print_stats(nSteps);
}


void go_home() {
    if( ! is_motor_ready())
      return;
      
    printf("\rGoing home from position %.2fdeg ...\n", steps2angle(nSteps));
    stepper_set_steps(&stepper, -nSteps);
    nSteps = 0;
    
    print_stats(nSteps);
}


void set_home() { 
    printf("\rSet current position (%.2fdeg) as new home ...\n", steps2angle(nSteps));
    nSteps = 0;
    
    print_stats(nSteps);
}


void dispatch_interrupts(uint8_t interrupt_mask, uint8_t value_mask) {
    clock_t interrupt_time = clock() / (CLOCKS_PER_SEC / 1000);
    if((1<<0) & interrupt_mask) { // interrupt on pin 0
        if((interrupt_mask & value_mask) == 1) { // pin 0 is high
            if( ! dynamic_flag) {
                advance(nStepsPerInterrupt);
            }
        } else if(last_interrupt_time_pin0 != 0 && dynamic_flag) { // pin 0 is low, dynamic mode is set and this is not the first interrupt
            double angle_to_advance = (interrupt_time-last_interrupt_time_pin0)/100.;
            if(angle_to_advance < 0) {
                printf(". Pulse length < 100ms");  // somehow pulses < 100ms are not recognized correctly
                angle_to_advance = 0;
            }
            advance(angle2steps(angle_to_advance));
            printf(". Last step size: %.2fdeg", steps2angle(angle2steps(angle_to_advance)));
        }
        last_interrupt_time_pin0 = interrupt_time;
    }        
    last_value_mask     = value_mask;
}


void parse_arguments(int argc, char **argv) {
    int c;
    double avalue = 5; //default angle to advance by per interrupt
    int option_index = 0;

    while (1)
      {
       static struct option long_options[] =
         {
           {"dynamic",    no_argument, &dynamic_flag, 1},
           {"record",     no_argument, &no_record_flag,  1},
           {"trigger",    no_argument, &triggered_flag,  1},
           {"angle",      required_argument, NULL, 'a'},
           {"gear-ratio", required_argument, NULL, 'g'},
           {"steps-per-revolution", required_argument, NULL, 's'},
           {"step-mode",  required_argument, NULL, 'm'},
           {"sweep-time",  required_argument, NULL, 'w'},
           {"n-aquisitions",  required_argument, NULL, 'n'},
           {NULL, 0, NULL, 0}
         };

       c = getopt_long(argc, argv, "tdra:g:s:m:n:w:?h",
                        long_options, &option_index);

       if (c == -1)
       {
         break;
       }

       switch (c)
         {
         case 'a':
           if( ! strtod(optarg, NULL) )
           {
             printf ("option -a requires a float as value\n");
             exit(1);
           }
           avalue = strtod(optarg, NULL); // nStepsPerInterrupt is set later to make sure gear_ratio is already set
           break;
         case 'g':
           if( ! strtod(optarg, NULL) )
           {
             printf ("option -g requires a float as value\n");
             exit(1);
           }
           gear_ratio = strtod(optarg, NULL);
           break;
         case 's':
           if( ! strtod(optarg, NULL) )
           {
             printf ("option -s requires a float as value\n");
             exit(1);
           }
           steps_per_revolution = strtod(optarg, NULL);
           break;
         case 'm':
           if( ! strtod(optarg, NULL) )
           {
             printf ("option -m requires an integer as value\n");
             exit(1);
           }
           step_mode = strtod(optarg, NULL);
           if ( step_mode != 1 && step_mode != 2 && step_mode != 4 && step_mode != 8)
           {
               printf("step-mode can only be 1,2,4 or 8 (resp 1, 1/2, 1/4 and 1/8 steps)\n");
               exit(1);
           }
           break;
         case 'w':
           if( ! strtod(optarg, NULL) )
           {
             printf ("option -w requires an integer as value\n");
             exit(1);
           }
           sweep_time = strtod(optarg, NULL);
           break;
         case 'n':
           if( ! strtod(optarg, NULL) )
           {
             printf ("option -n requires an integer as value\n");
             exit(1);
           }
           n_aquisitions = strtod(optarg, NULL);
           break;
         case 'd':
           dynamic_flag = 1;
           break;
         case 'r':
           no_record_flag = 1;
           break;
         case 't':
           triggered_flag = 1;
           break;
         case 'h':
         case '?':
           display_usage();
           exit(0);
         default:
           break;
         }
      }
    
    if(dynamic_flag && triggered_flag)
    {
       printf("using triggered-mode (-t) and dynamic-mode (-d) at the same time is useless\n");
       exit(1);
    }
    
    if(triggered_flag && (sweep_time == 0 || n_aquisitions ==0))
    {
      printf("provide a sweep time of the experiment (-w) and a number of aquisitions (-n) when using triggered mode \n");
      exit(1);
    }
                      
    nStepsPerInterrupt = angle2steps(avalue);
}

void pi_sleep(int seconds) {
    #ifdef __unix__
    sleep(seconds);
    #elif defined _WIN32
    Sleep(seconds*1000);
    #endif
}


int main(int argc, char **argv) {
    int c;
    bool first_run = true;

    char *logfile_mode = "w";
    char strTime[80];
    char logfile_name[95];
    time_t t;
    struct tm *ts;
  
    parse_arguments(argc, argv);
  
    // Prepare logfile 
    if( ! no_record_flag) {
      t = time(NULL);
      ts = localtime(&t);
      strftime(strTime, 80, "%Y-%m-%d_%H-%M-%S", ts);
      sprintf(logfile_name, "goniometer_%s.log", strTime);
      logfile = fopen(logfile_name, logfile_mode);  
    }

    // Establish IP connection to brick deamon brickd
    IPConnection ipcon;
    if(ipcon_connect(&ipcon, HOST, PORT) < 0) {
        fprintf(stderr, "Could not create IP connection to brickd. Is brickd running?\n");
        exit(1);
    }

    // Create IO4-device object
    io4_create(&io, IO4_UID, &ipcon); 

    // Create stepper-device object
    stepper_create(&stepper, STEPPER_UID, &ipcon); 

    // Configure stepper driver
    stepper_set_motor_current(&stepper, 750); // 750mA
    stepper_set_step_mode(&stepper, step_mode); // 1/8 step mode
    stepper_set_max_velocity(&stepper, 1000); // Velocity 1000 steps/s
    stepper_set_speed_ramping(&stepper, 500, 500); // Slow acceleration & deacelleration (500 steps/s^2),
    stepper_set_sync_rect(&stepper, true);// Enable synchronous rectification to allow setting the decay mode
    stepper_set_decay(&stepper, 40000); // Set decay mode to be considerably slower then "fast decay"
    stepper_enable(&stepper);

    if(triggered_flag) {
        printf("Trigger mode: This programm will trigger the aquisition each %dsec for %d times\n", sweep_time, n_aquisitions);
        printf("========================================\n");
        printf("Before each trigger the motor will advance by %d (%.2fdeg)\n", nStepsPerInterrupt, steps2angle(nStepsPerInterrupt));
        printf("Gear ratio is set to %f \n", gear_ratio);

        if( ! no_record_flag) {
          printf("Writing logfile to ./%s\n", logfile_name);
          fprintf(logfile, ";Running in triggered mode\n");
          fprintf(logfile, "; sweep time = %d\n", sweep_time);
          fprintf(logfile, "; n_aquisitions = %d\n", n_aquisitions);
          fprintf(logfile, "; steps_per_interrupt = %d\n", nStepsPerInterrupt);
          fprintf(logfile, "; gear ratio = %f \n", gear_ratio);
         }

        printf("Setting pin 1 to low.\n");                      
        io4_set_configuration(&io, 1<<1, 'o', false);  // set output pin to low to begin with
        
        while(n_aquisitions > 0) {
            // advance to next position
            if( ! first_run) {
                advance(nStepsPerInterrupt);
                printf("Advancing...");
                while( ! is_motor_ready()) {
                    pi_sleep(1);
                    printf(".");
                }
            } else {
                first_run = false;
            }
            printf("\n");
            
            // output a 1 sec pulse to pin 1
            io4_set_configuration(&io, 1<<1, 'o', true);
            pi_sleep(1);
            io4_set_configuration(&io, 1<<1, 'o', false);
            printf("Triggering experiment...\n");
            
            // wait for experiment to finish
            pi_sleep(sweep_time);
            
            --n_aquisitions;
        }
        
        stepper_disable(&stepper);
        // Disconnect from brickd
        ipcon_destroy(&ipcon);
        
        exit(0);
    }    
    // Configure pin 0 to be a floating input
    io4_set_configuration(&io, 1<<0, 'i', false);
    // Enable interrupt on pin 0 
    io4_set_interrupt(&io, 1 << 0); // TTL pulses for advance go on pin 0
  	// io4_set_interrupt(&io, 1 << 1); // home button goes on pin 1
  	// io4_set_interrupt(&io, 1 << 2); // step size button goes on pin 2

    // Register callback for interrupts
    io4_register_callback(&io, IO4_CALLBACK_INTERRUPT, (void*)dispatch_interrupts, NULL);

    
    if(dynamic_flag) {
        printf("Dynamic mode: The angle by which the motor advances corresponds to the TTL pulse length.\n");
        printf(" (Thats the time pin 0 is high. 10ms = 0.1deg). The step size argument will be ignored.\n");
        printf("========================================/n");

        if( ! no_record_flag) {
          printf("Writing logfile to ./%s\n", logfile_name);
          fprintf(logfile, ";Running in dynamic mode 10ms = 0.1deg\n");
          fprintf(logfile, "; gear ratio = %f \n", gear_ratio);
        }
    } else {
        printf("Steps per interrupt %d (%.2fdeg).\n", nStepsPerInterrupt, steps2angle(nStepsPerInterrupt));

        if( ! no_record_flag) {
          printf("Writing logfile to ./%s\n", logfile_name);
          fprintf(logfile, ";Running in key triggered mode\n");
          fprintf(logfile, "; steps_per_interrupt = %d\n", nStepsPerInterrupt);
          fprintf(logfile, "; gear ratio = %f \n", gear_ratio);
        }
    }
    printf("Gear ratio is set to %f \n", gear_ratio);
    printf("Waiting for interrupts on pin 0.\n");
    printf(" Press h<enter> to go to the home position.\n Press H<enter> to set current position as home.\n Press a<enter> to advance (A backwards).\n Press q<enter> to quit and display statistics\n");    

    while((c = getchar()) != 'q') {
        if(c=='a')
            advance(nStepsPerInterrupt);
        if(c=='A')
            advance(-nStepsPerInterrupt);
        if(c=='h')  
            go_home();
        if(c=='H')  
            set_home();
    }
    
        
    stepper_disable(&stepper);
    // Disconnect from brickd
    ipcon_destroy(&ipcon);

    print_stats(nSteps);
    printf("\n");
    if( ! no_record_flag) {
      fclose(logfile);
    }

    return 0;
}
