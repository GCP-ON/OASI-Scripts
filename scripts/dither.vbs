' MaxIm DL Dither Script with 180s exposures

Set Maxim = CreateObject("MaxIm.Application")
Set Camera = Maxim.Camera
Set Telescope = Maxim.Telescope

' Check if telescope is connected
If Not Telescope.Link Then
    WScript.Echo "Telescope not connected. Connect before running."
    WScript.Quit
End If

' Check if camera is connected
If Not Camera.Link Then
    WScript.Echo "Camera not connected. Connect before running."
    WScript.Quit
End If

' Define dither step size in arcseconds (converted to degrees)
ditherSizeArcsec = 10
ditherStepDeg = ditherSizeArcsec / 3600

' Define dither pattern: up, right, down, left, center
Dim dx(), dy()
dx = Array( 0,  ditherStepDeg,  0, -ditherStepDeg, 0)
dy = Array( ditherStepDeg, 0, -ditherStepDeg, 0, 0)

nSteps = UBound(dx)

' Get current telescope coordinates
RA0 = Telescope.RightAscension
Dec0 = Telescope.Declination

WScript.Echo "Starting dither pattern from RA: " & RA0 & ", Dec: " & Dec0

' Set camera exposure parameters
Camera.ExposeDark = False
Camera.ExposureTime = 180 ' seconds
Camera.BinX = 1
Camera.BinY = 1

For i = 0 To nSteps
    ' Adjust RA for declination to keep angular offset correct
    RAnew = RA0 + dx(i) / Cos(Dec0 * 3.1415926535 / 180)
    Decnew = Dec0 + dy(i)

    WScript.Echo "Step " & (i+1) & ": Slewing to RA=" & RAnew & ", Dec=" & Decnew
    Telescope.SlewToCoordinates RAnew, Decnew

    ' Wait for telescope to finish slewing
    Do While Telescope.Slewing
        WScript.Sleep 500
    Loop

    ' Take exposure
    WScript.Echo "Starting 180s exposure..."
    Camera.Expose
    Do While Not Camera.ImageReady
        WScript.Sleep 1000
    Loop

    ' Save image with zero-padded filename
    filename = "image_" & Right("0" & (i+1), 2) & ".fit"
    Camera.SaveImage filename
    WScript.Echo "Saved " & filename
Next

WScript.Echo "Dither sequence complete."

