$source = @"
public class BasicTest{
  public static int Add(int a, int b)
{return a + b;}}
"@
Add-Type -TypeDefinition $source
# Add-Type causes script block logging event 4103
