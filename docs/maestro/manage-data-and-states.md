Manage data and states | Flows | Maestro DocsMaestro Docs⌘CtrlkAskIntroductionMaestro StudioMaestro CLIMaestro CloudFlowsAPI ReferenceExamplesResourcesGitBook AssistantWorking...Thinking...Good morningI'm here to help you with the docs.What is this page about?What should I read next?Can you give an example?⌘CtrliAI Based on your contextSendMaestro DocsMaestro Flows overviewFlow Control and LogicFlow control and logic overviewHow to use SelectorsNested flowsWait commandsLoopsConditionsParameters and constantsSpecify and start devicesHooksTest in different localesPermissionsDetect MaestroJavaScriptJavaScript overviewRun and debug JavaScriptManage data and statesMake HTTP requestsGenerate synthetic dataWorkspace ManagementWorkspace management overviewProject configurationDesign your test architectureTest discovery and tagsSequential executionTest reports and artifactsRecord your FlowAI test analysisPowered by GitBookOn this pageAskJavaScriptManage data and statesShare data between scripts using the global output object, namespaces, and the maestro.copiedText property.Sharing data between UI elements and JavaScript scripts is essential for creating dynamic, resilient tests. This guide covers how to use the global output object, manage namespaces, and capture UI text for use in your logic.The output objectMaestro provides a single, global JavaScript object called output that persists throughout the entire execution of a Flow. Any data assigned to this object in one script or expression is immediately accessible to all subsequent scripts and Maestro commands.You can store strings, numbers, booleans, or complex objects within output. You can access or add information to the output object using standard JavaScript notation. In the following example, the value 'Hello World' is assigned to result (an arbitrary key name):Copy// myScript.js
output.result = 'Hello World'Once the Flow runs myScript.js, the value is assigned to the global object. You can then use that value in subsequent commands, such as inputText:Copy- runScript: myScript.js
- inputText: ${output.result}Output NamespacingBecause the output object is global, scripts can accidentally overwrite each other’s data if they use the same variable names. To prevent this, use namespaces, sub-objects named after your specific script or feature.Because the output object is global, different scripts can accidentally overwrite each other’s data if they use the same variable names. To prevent this, use namespaces (sub-objects named after your specific script or feature).For example, instead of assigning variables directly to the root of output, group them by context:authScript.jsprofileScript.jsCopyoutput.auth = {
    token: "abc-123",
    expiry: 3600
};Copyoutput.profile = {
    username: "MaestroUser",
    role: "Admin"
};You can then access this data using namespaced notation:Shared FunctionsThe output object can store functions as well as data. This is a powerful pattern for defining reusable logic, such as API helpers or complex string formatters, at the start of a Flow so they can be called from any subsequent script.In this example, we define a token generation function in apiUtils.js and make it globally available via the output.utils namespace:By loading the script in onFlowStart, the generateToken function becomes a reusable utility for the rest of the test execution:The maestro ObjectThe maestro object is a built-in utility that provides information about the current test environment and captured UI data.PropertyDescriptionmaestro.copiedTextContains the text retrieved by the most recent  copyTextFrom command.maestro.platformIdentifies the OS:

- ios
- android
- web

This is useful for conditional cross-platform logic.Capturing UI TextTo move text from your application into your JavaScript logic: Use the copyTextFrom command to store the content in the maestro.copiedText variable.Access that content in your JavaScript code or Maestro commands using maestro.copiedText.The following example copies content from a userName element and uses it to send a dynamic message:Next stepsNow that you already knows how to manage data when using JavaScript in Maestro Flows, access the following guides:Generate synthetic data: Use faker to create dynamic test data.Make HTTP requests: Use the built-in HTTP client for API interactions.PreviousRun and debug JavaScriptNextMake HTTP requestsLast updated 16 days agoThe output objectOutput NamespacingShared FunctionsThe maestro ObjectNext stepsCopy- inputText: ${output.auth.token}
- assertVisible: ${output.profile.username}Copy// apiUtils.js
function generateToken(prefix) {
    return prefix + "_" + Math.random().toString(36);
}

output.utils = {
    generateToken: generateToken
};CopyonFlowStart:
    - runScript: apiUtils.js
---
# Call the shared function to generate a new session token
- evalScript: ${output.sessionToken = output.utils.generateToken('session')}Copy- copyTextFrom: 
    id: userName # Target the userName element
- inputText: ${'Hello ' + maestro.copiedText} # Greets the user using the captured name
