﻿# Prevent screen lock

$WShell = New-Object -com "Wscript.Shell"

$song = @"
Well, you can tell by the way I use my walk
I'm a woman's man, no time to talk
Music loud and women warm, I've been kicked around
Since I was born
And now it's alright, it's okay
And you may look the other way
We can try to understand
The New York Times' effect on man
Whether you're a brother or whether you're a mother
You're stayin' alive, stayin' alive
Feel the city breakin' and everybody shakin'
And we're stayin' alive, stayin' alive
Ah, ha, ha, ha, stayin' alive, stayin' alive
Ah, ha, ha, ha, stayin' alive
Well now, I get low and I get high
And if I can't get either, I really try
Got the wings of Heaven on my shoes
I'm a dancin' man and I just can't lose
You know it's alright, it's okay
I'll live to see another day
We can try to understand
The New York Times' effect on man
Whether you're a brother or whether you're a mother
You're stayin' alive, stayin' alive
Feel the city breakin' and everybody shakin'
And we're stayin' alive, stayin' alive
Ah, ha, ha, ha, stayin' alive, stayin' alive
Ah, ha, ha, ha, stayin' alive (ohh)
Life goin' nowhere, somebody help me
Somebody help me, yeah
Life goin' nowhere, somebody help me, yeah
I'm stayin' alive
Well, you can tell by the way I use my walk
I'm a woman's man, no time to talk
Music loud and women warm
I've been kicked around since I was born
And now it's all right, it's okay
And you may look the other way
We can try to understand
The New York Times' effect on man
Whether you're a brother or whether you're a mother
You're stayin' alive, stayin' alive
Feel the city breakin' and everybody shakin'
And we're stayin' alive, stayin' alive
Ah, ha, ha, ha, stayin' alive, stayin' alive
Ah, ha, ha, ha, stayin' alive
Life goin' nowhere, somebody help me
Somebody help me, yeah
Life goin' nowhere, somebody help me, yeah
I'm stayin' alive
Life goin' nowhere, somebody help me
Somebody help me, yeah (ah, ah, ah)
Life goin' nowhere, somebody help me, yeah
I'm stayin' alive
Life goin' nowhere, somebody help me
Somebody help me, yeah (ah, ah, ah, ay)
Life goin' nowhere, somebody help me, yeah
I'm stayin' alive
Life goin' nowhere, somebody help me
Somebody help me, yeah (ohh)
Life goin' nowhere, somebody help me, yeah
I'm stayin' alive
"@

$lyrics = $song.Split([Environment]::NewLine)
$count = 0
while($true) {
    $currDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host $currDate - $lyrics[$count]
    $count += 1
    if ($count -eq $lyrics.Count) {
     $count = 0
    }
    $WShell.sendkeys("{SCROLLLOCK}") 
    Start-Sleep -s 30  
    $WShell.sendkeys("{SCROLLLOCK}")
}