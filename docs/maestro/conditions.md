Conditions | Flows | Maestro DocsMaestro Docs⌘CtrlkAskIntroductionMaestro StudioMaestro CLIMaestro CloudFlowsAPI ReferenceExamplesResourcesGitBook AssistantWorking...Thinking...Good morningI'm here to help you with the docs.What is this page about?What should I read next?Can you give an example?⌘CtrliAI Based on your contextSendMaestro DocsMaestro Flows overviewFlow Control and LogicFlow control and logic overviewHow to use SelectorsNested flowsWait commandsLoopsConditionsParameters and constantsSpecify and start devicesHooksTest in different localesPermissionsDetect MaestroJavaScriptJavaScript overviewRun and debug JavaScriptManage data and statesMake HTTP requestsGenerate synthetic dataWorkspace ManagementWorkspace management overviewProject configurationDesign your test architectureTest discovery and tagsSequential executionTest reports and artifactsRecord your FlowAI test analysisPowered by GitBookOn this pageAskFlow Control and LogicConditionsExecute commands conditionally based on visibility, platform, or custom expressions.Conditions allow you to execute commands or entire Flows only when specific criteria are met. This is useful for handling platform-specific logic (Android vs. iOS vs. Web), managing A/B tests, or dealing with dynamic UI elements like onboarding screens or permission dialogs.Keep your tests simpleOverusing conditional logic can make your Flows hard to read and debug. Prefer separate Flows for significantly different scenarios.Supported conditionsIn Maestro, conditions are primarily handled using the when argument. It can be attached to several commands. If the condition inside the when block evaluates to true, Maestro executes the command; otherwise, Maestro simply skips that command and moves on to the next one.The following table lists the available conditions you can use to define the conditional execution of your Flow.ConditionDescriptionvisibleExecuted if the element matching the selector is visible. The element must be defined using one or more Selectors.notVisibleExecuted if the element matching the selector is not visible. The element must be defined using one or more  Selectors.platformExecuted if the current platform matches (Android, iOS, or Web).trueExecuted if the JavaScript expression evaluates to true.Common use casesHandling platform differencesMobile apps often have different UI or behaviors on Android, iOS, or Web. You can use the platform condition to run platform-specific Flows.In this example, the test executes a specific subflow to handle permissions, depending on whether the device is running Android, iOS, or Web. Copy- runFlow:
      when:
      platform: Android
    file: subflows/android-permissions.yaml

- runFlow:
    when:
      platform: iOS
    file: subflows/ios-permissions.yaml
    
- runFlow:
    when:
      platform: Web
    file: subflows/web-permissions.yamlHandling dynamic stateSometimes an element may or may not appear, such as a "Rate this App" popup or a newsletter signup. You can handle these dynamic states using two different patterns:The runFlow / when blockThe optional propertyThis is the most idiomatically expressive way to handle conditions. It clearly defines the intent "Only run these commands when this condition is met." You combine runFlow and when: Using the optional property is simpler for single-command interactions. It allows the step to fail without failing the entire test. Adding a label helps maintain clarity on why the step is there.Relying on unstable UI states for conditions can lead to flaky tests. Ensure your visible selectors are unique and reliable.Using notVisible for negative conditionsYou can use the notVisible condition to handle inverse or “else” scenarios where an action should occur only when a specific element is not present on the screen.For example, the following command taps Standard Login only if the Biometric Login option is not visible. The runFlow command is used here because the tapOn command itself does not support conditional logic:This approach allows your tests to adapt to different UI states.Running multiple commandsYou don't always need to create a separate file for conditional steps. You can use the commands list to define multiple actions inline.In this example, if the "Welcome to our App" text is visible, the flow executes a sequence of taps to navigate through the onboarding screen.Multiple conditionsYou can combine multiple conditions in a single when block. Note that all conditions must be met (AND logic) for the commands to execute.In this example, the Allow button is tapped only if the platform is Android AND the Allow Notifications text is visible.Advanced logic with JavaScriptFor more complex logic, such as feature flags or checking variables, use the true condition with a JavaScript expression.In this example, the new-feature-test.yaml subflow is executed only if the IS_FEATURE_ENABLED variable evaluates to true.If your JavaScript condition is longer than one line, move the logic into a separate .js file and use the output variable to keep your YAML clean. The following example shows how to move the logic to an external file. First, create your script logic:Then, reference it in your Flow:Next stepsNow that you understand how to use conditions in your Flows, learn how to use parameters and constants or explore all the possibilities of using JavaScript to create tests.PreviousLoopsNextParameters and constantsLast updated 21 days agoSupported conditionsCommon use casesCopy- runFlow:
    when:
      visible: "Dismiss"
    commands:
      - tapOn: "Dismiss"Copy- tapOn:
    text: "Dismiss"
    optional: true
    label: "Dismiss popup if it exists"Copy- runFlow:
    when:
      notVisible: "Biometric Login"
    commands:
      - tapOn: "Standard Login"Copy- runFlow:
    when:
      visible: "Welcome to our App"
    commands:
      - tapOn: "Next"
      - tapOn: "Get Started"Copy- runFlow:
    when:
      platform: Android
      visible: "Allow Notifications"
    commands:
      - tapOn: "Allow"Copy- runFlow:
    when:
      true: ${IS_FEATURE_ENABLED == true}
    file: subflows/new-feature-test.yamlCopy// checkFeature.js
output.shouldRunTest = (MAESTRO_PLATFORM === 'Android' && someComplexCalculation() > 10);Copy- runScript: checkFeature.js
- runFlow:
    when:
      true: ${output.shouldRunTest}
    file: subflows/advanced-test.yaml
