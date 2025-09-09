$source = @"
public class BasicTest{
  public static int Add(int a, int b)
{return a + b;}}
"@
Add-Type -TypeDefinition $source
# Add-Type causes the following logs as "suspicious"
# 	Script block logging event 4104 with level of "Warning" (first time per session only)
# 	Module logging event 4103 with level of "Information"
