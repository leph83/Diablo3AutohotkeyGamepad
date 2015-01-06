/*
  Diablo III joystick control
  Author: zarzare
  Version 1.0
*/
 
; Case sensitive, game window title
WindowTitle = Diablo III
 
; START OF CONFIG SECTION
 
; If your system has more than one joystick, increase this value to use a joystick
; other than the first. Sometimes even if you only have 1 joystick it won't be the first
; so try changing this if the script is not working.
JoystickNumber = 1
 
; Define which axes to use, default is for XBox 360
MoveXAxis = X
MoveYAxis = Y
MouseXAxis = U
MouseYAxis = R
SliderAxis = Z
 
; Increase the following value to make the mouse cursor move faster
; when controlling the mouse with the right stick
JoyMultiplier = 0.40
; Dead zone for the joystick on all axis, should be between 1 and 40
JoyThreshold = 10
; Move circle radius in percentages of the window height, keep this small for manoeuvring in tight places
MoveRadius = 20
; Far abilities radius in percentages of the window size independent on each axis (basically an ellipse)
; Abilities with the far property set will be cast somewhere on this ellipse
FarRadius = 95
; If the movement circle is not centered around the character try changing this value
HeightCorrection = 0.43
 
; Key mapped to moving without attacking
MoveKey = Space
; Stand still key
StandStillKey = Shift
 
; Position override button. While this button is pressed mouse position will be determined by left stick position
; Allows to move the mouse fast anywhere within the rectangle determined by FarRadius
; While this button is pressed the far property of each ability is ignored and movement is disabled
PositionOverrideButton = 5
 
; Define skills mapping, this are the keys to press
; 2 special values:
; MB1 - Left mouse button
; MB2 - Right mouse button
; notice by default left mouse button is defined to both sliders
; one with stand still (for attacking) and one without (for picking up loot)
RightSlider = MB1
LeftSlider = MB1
Button1 = 1
Button2 = 2
Button3 = 3
Button4 = 4
Button5 =
Button6 = MB2
Button7 = Tab
Button8 = Esc
Button9 =
Button10 =
POVUp = t
POVRight = i
POVDown = q
POVLeft = Alt
 
; Define the list of skills that should be used with stand still
StandStillList := ["LeftSlider", "Button6"]
 
; Define the list of skills that should be cast far from character
; As an example I use this for teleport just point the stick in the direction and press the button
FarList := ["Button3"]
 
; END OF CONFIG SECTION
 
 
#NoEnv
#Persistent
#SingleInstance force
#MaxHotkeysPerInterval, 200
 
JoystickPrefix = %JoystickNumber%Joy
 
GetKeyState, joy_name, %JoystickPrefix%Name
if joy_name =
{
    MsgBox Joystick is disconnected
    ExitApp
}
 
; Calculate the axis displacements that are needed to start moving the cursor:
JoyThresholdUpper := 50 + JoyThreshold
JoyThresholdLower := 50 - JoyThreshold
 
old_pressed_buttons := Object()
joy_angle = 0
 
SendMode Input
SetTitleMatchMode, 3
SetTimer, WatchJoystick, 10  ; Monitor the movement of the joystick.
 
return  ; End of auto-execute section.
 
atan2(y,x)
{
   return dllcall("msvcrt\atan2","Double",y, "Double",x, "CDECL Double")
}
 
ReleaseKey(key)
{
    if key =
        return
    if key = MB1
        Click up
    else if key = MB2
        Click up right
    else
        Send {%key% up}
}
 
PressKey(key)
{
    if key =
        return
    if key = MB1
        Click down
    else if key = MB2
        Click down right
    else
        Send {%key% down}
}
 
IsButtonInList(ByRef but_list, but)
{
    for index, element in but_list
    {
        if element = %but%
            return true
    }
    return false
}
 
IsStandStillNeeded(ByRef pressed)
{
    global StandStillList
    for index, element in pressed
    {
        if IsButtonInList(StandStillList, element)
            return true
    }
    return false
}
 
IsFarNeeded(ByRef pressed)
{
    global FarList
    for index, element in pressed
    {
        if IsButtonInList(FarList, element)
            return true
    }
    return false
}
 
CheckReleaseButtons(ByRef pressed_buttons)
{
    global old_pressed_buttons
    for index, but in old_pressed_buttons
    {
        if not IsButtonInList(pressed_buttons, but)
        {
            ReleaseKey(%but%)
        }
    }
}
 
CheckPressButtons(ByRef pressed_buttons)
{
    global old_pressed_buttons
    for index, but in pressed_buttons
    {
        if not IsButtonInList(old_pressed_buttons, but)
        {
            PressKey(%but%)
        }
    }
    old_pressed_buttons := pressed_buttons
}
 
GetPressedButtons()
{
    global JoystickPrefix, SliderAxis, JoyThresholdUpper, JoyThresholdLower
    pressed_buttons := Object()
    GetKeyState, slider_val, %JoystickPrefix%%SliderAxis%
    if slider_val > %JoyThresholdUpper%
        pressed_buttons.insert("LeftSlider")
    else if slider_val < %JoyThresholdLower%
        pressed_buttons.insert("RightSlider")
    Loop 10
    {
        if GetKeyState(JoystickPrefix . A_Index)
        {
            pressed_buttons.insert("Button" . A_Index)
        }
    }
    GetKeyState, joy_pov, %JoystickPrefix%POV
    if joy_pov != -1
    {
        if (joy_pov >= 31500) or (joy_pov <= 4500)
            pressed_buttons.insert("POVUp")
        if (joy_pov >= 4500) and (joy_pov <= 13500)
            pressed_buttons.insert("POVRight")
        if (joy_pov >= 13500) and (joy_pov <= 22500)
            pressed_buttons.insert("POVDown")
        if (joy_pov >= 22500) and (joy_pov <= 31500)
            pressed_buttons.insert("POVLeft")
    }
 
    return pressed_buttons
}
 
CorrectJoyPos(joy_pos)
{
    global JoyThresholdLower, JoyThresholdUpper, JoyThreshold
    delta = 0.0
    if joy_pos > %JoyThresholdUpper%
        delta := joy_pos - JoyThresholdUpper
    else if joy_pos < %JoyThresholdLower%
        delta := joy_pos - JoyThresholdLower
    delta := delta * 50 / (50 - JoyThreshold)
    return delta
}
 
WatchJoystick:
    IfWinNotActive, %WindowTitle%
        return
    
    GetKeyState, joyx, %JoystickPrefix%%MoveXAxis%
    GetKeyState, joyy, %JoystickPrefix%%MoveYAxis%
    
    joyx := CorrectJoyPos(joyx)
    joyy := CorrectJoyPos(joyy)
 
    far_button_pressed := false
    if GetKeyState(JoystickPrefix . PositionOverrideButton)
        far_button_pressed := true
 
    buttons_pressed := GetPressedButtons()
    
    shift_needed := IsStandStillNeeded(buttons_pressed)
 
    if (joyx != 0) or (joyy != 0) or (far_button_pressed)
    {
        if (not shift_needed) and (not far_button_pressed)
            buttons_pressed.insert("MoveKey")
        WinGetPos,,, total_width, total_height, A
        x_axis_centre := total_width / 2
        y_axis_centre := total_height * HeightCorrection
 
        if (far_button_pressed)
        {
            new_xpos := x_axis_centre * joyx * FarRadius / 5000 + x_axis_centre
            new_ypos := y_axis_centre * joyy * FarRadius / 5000 + y_axis_centre
        } else if IsFarNeeded(buttons_pressed)
        {
            joy_angle := atan2(joyy, joyx)
            radius_x := x_axis_centre * FarRadius / 100
            radius_y := y_axis_centre * FarRadius / 100
            new_xpos := Round(Cos(joy_angle) * radius_x + x_axis_centre)
            new_ypos := Round(Sin(joy_angle) * radius_y + y_axis_centre)
        } else
        {
            joy_angle := atan2(joyy, joyx)
            radius_x := MoveRadius * y_axis_centre / 100
            radius_y := radius_x
            new_xpos := Round(Cos(joy_angle) * radius_x + x_axis_centre)
            new_ypos := Round(Sin(joy_angle) * radius_y + y_axis_centre)
        }
        MouseMove new_xpos, new_ypos, 0
    } else
    {
        GetKeyState, joyx, %JoystickPrefix%%MouseXAxis%
        GetKeyState, joyy, %JoystickPrefix%%MouseYAxis%
 
        deltax := CorrectJoyPos(joyx)
        deltay := CorrectJoyPos(joyy)
 
        if (deltax != 0) or (deltay != 0)
            MouseMove, deltax * JoyMultiplier, deltay * JoyMultiplier, 0, R
    }
 
    if (shift_needed)
        buttons_pressed.insert("StandStillKey")
    CheckReleaseButtons(buttons_pressed)
    CheckPressButtons(buttons_pressed)
 
    return