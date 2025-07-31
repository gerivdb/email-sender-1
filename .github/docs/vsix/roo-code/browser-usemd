---
description: Learn how Roo Code can control a browser to automate web tasks, gather information, and interact with web applications using AI-powered browser automation.
keywords: browser automation,web scraping,browser control,AI browser,web automation,Roo Code browser
image: /img/social-share.jpg
---

# Browser Use


Roo Code provides sophisticated browser automation capabilities that let you interact with websites directly from VS Code. This feature enables testing web applications, automating browser tasks, and capturing screenshots without leaving your development environment.




Model Support RequiredBrowser Use within Roo Code requires the use of Claude Sonnet 3.5 or 3.7



## How Browser Use Works​


By default, Roo Code uses a built-in browser that:


- Launches automatically when you ask Roo to visit a website
- Captures screenshots of web pages
- Allows Roo to interact with web elements
- Runs invisibly in the background


All of this happens directly within VS Code, with no setup required.



## Using Browser Use​


A typical browser interaction follows this pattern:


Important: Browser Use requires Claude Sonnet 3.5 or 3.7 model.


1. Ask Roo to visit a website
2. Roo launches the browser and shows you a screenshot
3. Request additional actions (clicking, typing, scrolling)
4. Roo closes the browser when finished


For example:







## How Browser Actions Work​


The browser_action tool controls a browser instance that returns screenshots and console logs after each action, allowing you to see the results of interactions.


Key characteristics:


- Each browser session must start with launch and end with close
- Only one browser action can be used per message
- While the browser is active, no other tools can be used
- You must wait for the response (screenshot and logs) before performing the next action


### Available Browser Actions​


ActionDescriptionWhen to Use`launch`Opens a browser at a URLStarting a new browser session`click`Clicks at specific coordinatesInteracting with buttons, links, etc.`type`Types text into active elementFilling forms, search boxes`scroll_down`Scrolls down by one pageViewing content below the fold`scroll_up`Scrolls up by one pageReturning to previous content`close`Closes the browserEnding a browser session

## Browser Use Configuration/Settings​


Default Browser Settings- Enable browser tool: Enabled
- Viewport size: Small Desktop (900x600)
- Screenshot quality: 75%
- Use remote browser connection: Disabled


### Accessing Settings​


To change Browser / Computer Use settings in Roo:


1. 
Open Settings by clicking the gear icon  → Browser / Computer Use




### Enable/Disable Browser Use​


Purpose: Master toggle that enables Roo to interact with websites using a Puppeteer-controlled browser.


To change this setting:


1. 
Check or uncheck the "Enable browser tool" checkbox within your Browser / Computer Use settings




### Viewport Size​


Purpose: Determines the resolution of the browser session Roo Code uses.


Tradeoff: Higher values provide a larger viewport but increase token usage.


To change this setting:


1. 
Click the dropdown menu under "Viewport size" within your Browser / Computer Use settings

2. 
Select one of the available options:

Large Desktop (1280x800)
Small Desktop (900x600) - Default
Tablet (768x1024)
Mobile (360x640)


3. 
Select your desired resolution.




### Screenshot Quality​


Purpose: Controls the WebP compression quality of browser screenshots.


Tradeoff: Higher values provide clearer screenshots but increase token usage.


To change this setting:


1. 
Adjust the slider under "Screenshot quality" within your Browser / Computer Use settings

2. 
Set a value between 1-100% (default is 75%)

3. 
Higher values provide clearer screenshots but increase token usage:

40-50%: Good for basic text-based websites
60-70%: Balanced for most general browsing
80%+: Use when fine visual details are critical





### Remote Browser Connection​


Purpose: Connect Roo to an existing Chrome browser instead of using the built-in browser.


Benefits:


- Works in containerized environments and remote development workflows
- Maintains authenticated sessions between browser uses
- Eliminates repetitive login steps
- Allows use of custom browser profiles with specific extensions


Requirements: Chrome must be running with remote debugging enabled.


To enable this feature:


1. 
Check the "Use remote browser connection" box in Browser / Computer Use settings

2. 
Click "Test Connection" to verify




#### Common Use Cases​


- DevContainers: Connect from containerized VS Code to host Chrome browser
- Remote Development: Use local Chrome with remote VS Code server
- Custom Chrome Profiles: Use profiles with specific extensions and settings


#### Connecting to a Visible Chrome Window​


Connect to a visible Chrome window to observe Roo's interactions in real-time:


macOS
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-debug --no-first-run

Windows
"C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222 --user-data-dir=C:\chrome-debug --no-first-run


Linux
google-chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-debug --no-first-run