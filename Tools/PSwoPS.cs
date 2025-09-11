using System;
using System.Collections.ObjectModel;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;

/*
Simplified version of code originally authored by: Casey Smith, Twitter: @subTee
License: BSD 3-Clause

Compile with:
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /r:C:\Windows\assembly\GAC_MSIL\System.Management.Automation\1.0.0.0__31bf3856ad364e35\System.Management.Automation.dll /unsafe /platform:anycpu /out:PSwoPS.exe C:\Users\art\PowerShellForInfoSec\Tools\PSwoPS.cs
*/

 public class Program
 {
	 public static void Main()
	 {
		while(true)
		{		
			Console.Write("PS without PS >");
			string x = Console.ReadLine();
			Console.WriteLine(RunPSCommand(x));		
		}
	}
 
 	//Based on Jared Atkinson's And Justin Warner's Work
	public static string RunPSCommand(string cmd)
	{
		//Init stuff
		Runspace runspace = RunspaceFactory.CreateRunspace();
		runspace.Open();
		RunspaceInvoke scriptInvoker = new RunspaceInvoke(runspace);
		Pipeline pipeline = runspace.CreatePipeline();

		//Add commands
		pipeline.Commands.AddScript(cmd);

		//Prep PS for string output and invoke
		pipeline.Commands.Add("Out-String");
		Collection<PSObject> results = pipeline.Invoke();
		runspace.Close();

		//Convert records to strings
		StringBuilder stringBuilder = new StringBuilder();
		foreach (PSObject obj in results)
		{
			stringBuilder.Append(obj);
		}
		return stringBuilder.ToString().Trim();
	 } 
 }
