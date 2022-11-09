# NSLogger iPad Viewer  

### iPhone Client (2013/04/27)  
![](https://github.com/stkim1/NSLogger-iPad-Viewer/blob/master/ScreenShots/iphone_13_04_27.png?raw=true)  

### iPad Viewer (2013/05/10)  
![](https://github.com/stkim1/NSLogger-iPad-Viewer/blob/master/ScreenShots/ipad_13_05_09.png?raw=true)  

_Ver 0.4.1 is available on [the main repo](https://github.com/fpillet/NSLogger). (2013/08/03)_  

Derived from [Florent Pillet's NSLogger](https://github.com/fpillet/NSLogger), NSLogger iPad is an in-field logging tool to monitor your mobile application's behavior in unfabricated, real-world environments.  

You can utilize this project to monitor how your application behaves on cellular network, handles GPS data, and/or, treats frequent data exchange with backend outside of your office.  


## Minimum Requirements  
- iOS 6.1 and upward  
- iPad 2 or iPad mini gen 1  
- _iCloud not supported_  


## How to run demo  
1. Run iPad Viewer on an iPad with WiFi off and Bluetooth on.  
2. Run iOS client with Bluetooth on. (It's up to you to leave WiFi or cellular on).  
3. Start logging. Look at the Bluetooth mark on top right corner. :)  

## TODO  
### Search  
- Search is what makes NSLogger stand out, and my wish is to make the search feature as powerful as Desktop version.  
- Unlike OSX environment, iOS does not provide something similar to BWToolKit so we have to come up with something new but easy to use.  
- A proposal is made here that we are to drag and drop a searchable element into a basket of combinator, and to come up with a preset. Open up "Dragger" example. It's crude but I hope it explains the idea.  

### UI  
1. Preference : Transport On/Off, Network Setting, Export log data  
2. Multiple views to show connections to viewer  
3. Search for thread, Tag, and/or etc.  
4. Function name  
5. Time delta between logs  
6. Click to see detail  


### CoreData model  
1. Split log entity for performance : data for format such as height vs. actual data  
2. New entry for tag, function name  
3. Move reconnection count variable from LoggerConnection to LoggerClient entity  
4. Handle App lifecycle (active/inactive/background/terminate)  


#### Meanwhile, if you're interested…  
1. [Caught at the scene
](http://blog.colorfulglue.com/2012/12/caught-at-the-scene/)  
2. [NSLogger viewer architecture](http://blog.colorfulglue.com/2013/02/nslogger-viewer-architecture/)  

## Bluetooth Connection  
There are three Bluetooth frameworks and one API publicly opened in iOS  
1. [CoreBluetooth](http://developer.apple.com/library/ios/#documentation/CoreBluetooth/Reference/CoreBluetooth_Framework/_index.html)  
2. [External Accessary](http://developer.apple.com/library/ios/#documentation/ExternalAccessory/Reference/ExternalAccessoryFrameworkReference/_index.ht]ml)  
3. [GameKit](http://developer.apple.com/library/ios/#documentation/GameKit/Reference/GameKit_Collection/_index.html)  
4. [Bonjour over Bluetooth (DNS-SD)](http://developer.apple.com/library/ios/#qa/qa1753/_index.html#//apple_ref/doc/uid/DTS40011315)  

The one that is most clutter-free and provides best possible use case is, so far in my opinion, the last one. It requires no additional framework, library, and does not ask user to choose bluetooth connection. It simply finds the nearest possible service on Bluetooth interface and makes use of it.  

## License  
<pre>
Copyright (c) 2012-2014 Sung-Taek, Kim <stkim1@colorfulglue.com> All Rights Reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

Redistributions of  source code  must retain  the above  copyright notice,
this list of  conditions and the following  disclaimer. Redistributions in
binary  form must  reproduce  the  above copyright  notice,  this list  of
conditions and the following disclaimer  in the documentation and/or other
materials  provided with  the distribution.  Neither the  name of Sung-Tae
k Kim nor the names of its contributors may be used to endorse or promote
products  derived  from  this  software  without  specific  prior  written
permission.  THIS  SOFTWARE  IS  PROVIDED BY  THE  COPYRIGHT  HOLDERS  AND
CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT
NOT LIMITED TO, THE IMPLIED  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A  PARTICULAR PURPOSE  ARE DISCLAIMED.  IN  NO EVENT  SHALL THE  COPYRIGHT
HOLDER OR  CONTRIBUTORS BE  LIABLE FOR  ANY DIRECT,  INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY,  OR CONSEQUENTIAL DAMAGES (INCLUDING,  BUT NOT LIMITED
TO, PROCUREMENT  OF SUBSTITUTE GOODS  OR SERVICES;  LOSS OF USE,  DATA, OR
PROFITS; OR  BUSINESS INTERRUPTION)  HOWEVER CAUSED AND  ON ANY  THEORY OF
LIABILITY,  WHETHER  IN CONTRACT,  STRICT  LIABILITY,  OR TORT  (INCLUDING
NEGLIGENCE  OR OTHERWISE)  ARISING  IN ANY  WAY  OUT OF  THE  USE OF  THIS
SOFTWARE,   EVEN  IF   ADVISED  OF   THE  POSSIBILITY   OF  SUCH   DAMAGE.

************************** THE CODE IS BASED ON ******************************

<a href="https://github.com/fpillet/NSLogger">NSLogger</a> Copyright (c) 2010-2013, Florent Pillet All rights reserved. 
<a href="https://github.com/KieranLafferty/KLNoteViewController">KLNoteViewController</a> Copyright (c) 2012 Kieran Lafferty All rights reserved. 
<a href="https://github.com/kgn/KGNoise">KGNoise</a> Copyright (c) 2012 David Keegan (http://davidkeegan.com) All rights reserved
<a href="http://www.cocoawithlove.com/">Cocoa With Love</a> Copyright (c) 2007, 2008, 2010 Matt Gallagher. All rights reserved 
<a href="http://johnaugust.com/2013/introducing-courier-prime">Courier Prime</a> Copyright (c) 2013, Quote-Unquote Apps, with Reserved Font Name Courier Prime.
Lucida Grande, Lucida Grande Copyright (c) 1997, 2000, Bigelow & Holmes Inc. U.S. Pat. Des. 289,420. All rights reserved.
<a href="http://www.levien.com/type/myfonts/inconsolata.html">Inconsolata</a> Copyright 2006 Raph Levien. Released under the Apache 2 license.
<a href="http://www.styleseven.com">Digital-7</a> Copyright (c) 2008, Sizenko Alexander, Style-7 All rights reserved.</pre>

VER. 0.4.1  

_Updated : 2022/11/09_
