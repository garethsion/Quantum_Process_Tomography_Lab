TARGET   = goniometer
CC       = gcc
CFLAGS   = -std=c99 -Wall -Wno-parentheses -I.

LINKER   = gcc -o
LFLAGS   = -Wall -I. -lm 

# simple conditionals for Linux and MinGW (gcc under windows)
uname_S := $(shell sh -c 'uname -s 2>/dev/null || echo not')
# Linux. Tested
ifeq ($(uname_S),Linux)
	LFLAGS += -pthread
endif
# MinGW under Windows. Untested
ifneq (,$(findstring MINGW,$(uname_S)))
	LFLAGS += -lws2_32
endif
# Cygwin under Windows. Untested
ifneq (,$(findstring CYGWIN,$(uname_S)))
	LFLAGS += -lws2_32
endif
# Mac OSX. Untested
ifeq ($(uname_S),Darwin)
	LFLAGS += -pthread
endif

# change these to set the proper directories where each files shoould be
SRCDIR   = src
OBJDIR   = obj
BINDIR   = bin

SOURCES  := $(wildcard $(SRCDIR)/*.c)
INCLUDES := $(wildcard $(SRCDIR)/*.h)
OBJECTS  := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
rm       = rm -f


$(BINDIR)/$(TARGET): $(OBJECTS)
	@$(LINKER) $@ $(OBJECTS) $(LFLAGS)
	@echo "Linking complete!"

$(OBJECTS): $(OBJDIR)/%.o : $(SRCDIR)/%.c
	@$(CC) -c $< -o $@ $(CFLAGS)
	@echo "Compiled "$<" successfully!"

.PHONEY: clean
clean:
	@$(rm) $(OBJECTS)
	@echo "Cleanup complete!"

.PHONEY: remove
remove: clean
	@$(rm) $(BINDIR)/$(TARGET)
	@echo "Executable removed!"