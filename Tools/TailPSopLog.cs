using System;
using System.Diagnostics.Eventing.Reader;

// compile with:
// C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /out:C:\Users\IEuser\Desktop\TailPSopLog.exe C:\Users\IEUser\PowerShellForInfoSec\Tools\TailPSopLog.cs
// Kudos to Lee Holmes for the example log event watcher code

class Program
{
    static void Main(string[] args)
    {
        LoadEventLogs();

        Console.ReadKey();
    }

    private static void LoadEventLogs()
    {
        EventLogSession session = new EventLogSession();

        EventLogQuery query = new EventLogQuery("Microsoft-Windows-PowerShell/Operational", PathType.LogName, "*[System/EventID>=1]")
        {
            TolerateQueryErrors = true,
            Session = session
        };

        EventLogWatcher logWatcher = new EventLogWatcher(query);

        logWatcher.EventRecordWritten += new EventHandler<EventRecordWrittenEventArgs>(LogWatcher_EventRecordWritten);

        try
        {
            logWatcher.Enabled = true;
        }
        catch (EventLogException ex)
        {
            Console.WriteLine(ex.Message);
            Console.ReadLine();
        }
    }

    private static void LogWatcher_EventRecordWritten(object sender, EventRecordWrittenEventArgs e)
    {
        var time = e.EventRecord.TimeCreated;
        var id = e.EventRecord.Id;
        var level = e.EventRecord.Level;
        var desc = e.EventRecord.FormatDescription();

        Console.ForegroundColor = ConsoleColor.White;
        var scriptBlockLoggingEventId = 4104; var scriptBlockColor = ConsoleColor.Yellow;
        var moduleLoggingEventId = 4103; var moduleColor = ConsoleColor.Cyan;
        var scriptBlockExecutionStartEventId = 4105; var scriptBlockExecutionStartColor = ConsoleColor.Green;
        var scriptBlockExecutionStopEventId = 4106; var scriptBlockExecutionStopColor = ConsoleColor.Red;


        // From PowerShell Cookbook: PowerShell automatically logs all script blocks (using a logging level of Warning) that contain keywords and techniques commonly used in malicious contexts.
        if (id == scriptBlockLoggingEventId)
        {
            if (level == 5) // 1-Critical 2-Error 3-Warning 4-Info 5-verbose 0-LogAlways
            {
                Console.ForegroundColor = scriptBlockColor;
                Console.WriteLine("  Script Block Log");
            }
            else if (level == 3)
            {
                Console.ForegroundColor = ConsoleColor.DarkYellow;
                Console.WriteLine("  Automatic Script Block Log");
            }
            else { Console.WriteLine("!!!!!!!!!!!!!!!!!!!!!!!!!!! Wasn't expecting this level: {0}", level); }
        }
        else if (id == moduleLoggingEventId)
        {
            Console.ForegroundColor = moduleColor;
            Console.WriteLine("  Module Log");
        }
        else if (id == scriptBlockExecutionStartEventId)
        {
            Console.ForegroundColor = scriptBlockExecutionStartColor;
            Console.WriteLine("  Script Execution Start Log");
        }
        else if (id == scriptBlockExecutionStopEventId)
        {
            Console.ForegroundColor = scriptBlockExecutionStopColor;
            Console.WriteLine("  Script Execution Stop Log");
        }
        else
        {
            Console.WriteLine("");
        }

        Console.WriteLine("EventId: {0}     Time:  {1} Level: {2}\n{3}", id, time, level, desc);
        Console.ForegroundColor = ConsoleColor.Magenta;
        Console.Write("--------------------------------");
        Console.ForegroundColor = ConsoleColor.White;

    }
}
