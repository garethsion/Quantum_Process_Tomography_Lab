function value = GetCursorData()
format long;
datatip = datacursormode();
cursorInfo = getCursorInfo(datatip);
value = cursorInfo.Position;
end

