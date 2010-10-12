Bool traceEnabled = True;
function Action trace(Fmt fmt) = traceEnabled ? $display($format("[Trace] ")+fmt) : noAction;
