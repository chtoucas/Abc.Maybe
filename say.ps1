
function say-loud {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  write-host $Message -BackgroundColor DarkCyan -ForegroundColor Green
}

function carp {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  write-host $Message -BackgroundColor Red -ForegroundColor Yellow
}

function croak {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  write-host $Message -BackgroundColor Red -ForegroundColor Yellow
  Exit 1
}

function confess {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  write-host $Message -ForegroundColor Green
}
