#requires -version 2.0
function Add-RotateFlipFilter {    
    <#
        .Synopsis
            Adds a Rotate Filter to a list of filters, or creates a new filter
        .Description
            Adds a Rotate Filter to a list of filters, or creates a new filter
        .Example
            $image = Get-Image .\Try.jpg            
            $image = $image | Set-ImageFilter -filter (Add-RotateFlipFilter -flipHorizontal -passThru) -passThru                    
            $image.SaveFile("$pwd\Try2.jpg")
        .Parameter angle
            The Angle of the rotation.  Can only be 0, 90, 180, 270, or 360
        .Parameter flipHorizontal
            If set, the filter will flip images horizontally
        .Parameter flipVertical
            If set, the filter will flip images vertically
        .Parameter passthru
            If set, the filter will be returned through the pipeline.  This should be set unless the filter is saved to a variable.
        .Parameter filter
            The filter chain that the rotate filter will be added to.  If no chain exists, then the filter will be created
    #>
    param(
    [Parameter(ValueFromPipeline=$true)]
    [__ComObject]
    $filter,
               
    [ValidateSet(0, 90, 180, 270, 360)]
    [int]$angle,
    [switch]$flipHorizontal,
    [switch]$flipVertical,
    
    [switch]$passThru                      
    )
    
    process {
        if (-not $filter) {
            $filter = New-Object -ComObject Wia.ImageProcess
        } 
        $index = $filter.Filters.Count + 1
        if (-not $filter.Apply) { return }
        $scale = $filter.FilterInfos.Item("RotateFlip").FilterId
        $isPercent = $true
        if ($width -gt 1) { $isPercent = $false }
        if ($height -gt 1) { $isPercent = $false } 
        $filter.Filters.Add($scale)
        $filter.Filters.Item($index).Properties.Item("FlipHorizontal") = "$FlipHorizontal"       
        $filter.Filters.Item($index).Properties.Item("FlipVertical") = "$FlipVertical"
        $filter.Filters.Item($index).Properties.Item("RotationAngle") = $Angle
        if ($passthru) { return $filter }         
    }
}