#NSLogger-iPad-Viewer

Derived from [Florent Pillet's NSLogger](https://github.com/fpillet/NSLogger), NSLogger iPad Viewer is an in-field logging tool to monitor your mobile application's behavior in unfabricated, real-world environments. NSLogger iPad Viewer makes use of Bluetooth connection to transmit an application's logging traces.

This is extremely useful to monitor how your application behaves on cellular network, handles GPS data, and/or, treats frequent data exchange with backend.

##Minimum Requirements
iOS 5.1 and upward  
iPad 2 / iPad mini or higher  
<sup>*</sup>iCloud not supported.

##Documents, Example, and/or Wiki
You will see them at [the main repository](https://github.com/fpillet/NSLogger). All pull requests and issues are only accepted from there.  

##Status
As of today (May 9, 2013), I split the repo into two branches; release & development.   

A release version of 0.4 would be highly limited in terms of UI. Nontheless, its underlying logics are essentially the same as the development version and you could capture logging traces with WiFi/Bluetooth connection.    

Ver 0.4 is tested on iPad 2 for receiving 17,160 logging traces with 1,946 images for an hour. I believe it is stable enough to deploy outside.  

### Work-In-Progress
UI : Preference/Multi-Window/Search

###Questions
Throw 'em at [@stkim1](http://twitter.com/stkim1)

## How to run demo
1. Run NSLogger iPad Viewer with WiFi off and Bluetooth on from Setting.  
2. Run iOS client with Bluetooth on. (It's up to you to leave WiFi or cellular on).        
3. Start logging. Look at the Bluetooth mark on top right corner. :)  

##Screen Shots 
### iPhone Client (13/04/27)
<img width="320" src="https://raw.github.com/stkim1/NSLogger-iPad-Viewer/master/ScreenShots/iphone_13_04_27.png" />

###iPad Viwer (13/05/11)
<img width="576" src="https://raw.github.com/stkim1/NSLogger-iPad-Viewer/master/ScreenShots/ipad_13_05_11.png" />


##License
<pre>Modified BSD license.

Copyright (c) 2012-2013 Sung-Taek, Kim <stkim1@colorfulglue.com> All Rights Reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Any redistribution is done solely for personal benefit and not for any
   commercial purpose or for monetary gain.

4. No binary form of source code is submitted to App Store℠ of Apple Inc.

5. Neither the name of the Sung-Taek, Kim nor the names of its contributors may
   be used to endorse or promote products derived from  this software without 
   specific prior written permission.

THIS SOFTWARE IS PROVIDED BY COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
EXPRESS OR  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDER AND AND CONTRIBUTORS BE LIABLE 
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

************************** THE CODE IS BASED ON ******************************

<a href="https://github.com/fpillet/NSLogger">NSLogger</a> Copyright (c) 2010-2012, Florent Pillet All rights reserved. 
<a href="https://github.com/KieranLafferty/KLNoteViewController">KLNoteViewController</a> Copyright (c) 2012 Kieran Lafferty All rights reserved. 
<a href="https://github.com/kgn/KGNoise">KGNoise</a> Copyright (c) 2012 David Keegan (http://davidkeegan.com) All rights reserved
<a href="http://www.cocoawithlove.com/">Cocoa With Love</a> Copyright (c) 2007, 2008, 2010 Matt Gallagher. All rights reserved 
<a href="http://johnaugust.com/2013/introducing-courier-prime">Courier Prime</a> Copyright (c) 2013, Quote-Unquote Apps, with Reserved Font Name Courier Prime.
Lucida Grande, Lucida Grande Copyright (c) 1997, 2000, Bigelow & Holmes Inc. U.S. Pat. Des. 289,420. All rights reserved.
<a href="http://www.levien.com/type/myfonts/inconsolata.html">Inconsolata</a> Copyright 2006 Raph Levien. Released under the Apache 2 license.
<a href="http://www.styleseven.com">Digital-7</a> Copyright (c) 2008, Sizenko Alexander, Style-7 All rights reserved.</pre>

_VER. 0.4.0_<br/>
_Updated : May 9, 2013_
