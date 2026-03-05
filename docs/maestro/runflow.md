runFlow | API Reference | Maestro DocsMaestro Docs⌘CtrlkAskIntroductionMaestro StudioMaestro CLIMaestro CloudFlowsAPI ReferenceExamplesResourcesGitBook AssistantWorking...Thinking...Good morningI'm here to help you with the docs.What is this page about?What should I read next?Can you give an example?⌘CtrliAI Based on your contextSendMaestro DocsCommands overviewCommands availableaddMediaassertNoDefectsWithAIassertNotVisibleassertScreenshotassertTrueassertVisibleassertWithAIbackclearKeychainclearStatecopyTextFromdoubleTapOneraseTextevalScriptextendedWaitUntilextractTextWithAIhideKeyboardinputTextkillApplaunchApplongPressOnopenLinkpasteTextpressKeyrepeatretryrunFlowrunScriptscrollscrollUntilVisiblesetAirplaneModesetClipboardsetLocationsetOrientationsetPermissionsstartRecordingstopAppstopRecordingswipetakeScreenshottapOntoggleAirplaneModetravelwaitForAnimationToEndSelectorsWorkspace configurationPowered by GitBookOn this pageAskCommands availablerunFlowExecute a subflow file with optional environment variables.The runFlow command executes a sequence of commands from another Flow file or from an inline definition. This command helps you modularize tests and reuse common sequences, such as a login process. Inline subflows (using the commands parameter) are especially useful for conditional logic or for grouping a few steps under a clear label.ParametersThe runFlow command accepts the following parameters.ParameterTypeDescriptionfilestringThe relative path to the Flow file to execute.labelstringA short description of what the subflow does. Shown in reports and helps with readability and maintenance.envmapA map of key-value pairs to pass as environment variables to the subflow.commandslistA list of commands to execute inline. Use this instead of the file parameter for self-contained Flows.Usage examplesThe following examples demonstrate how to use the runFlow command.Run a separate Flow fileTo reuse a common sequence of steps, define them in a separate file and call them with runFlow. For example, you can define a login sequence once and reuse it in multiple tests. The following Login Flow is defined in one file and reused in the other two Flows (Profile and Settings).Login.yamlProfile.yamlSettings.yamlCopyappId: com.example.app
---
- launchApp
- tapOn: Username
- inputText: Test User
- tapOn: Password
- inputText: Test Password
- tapOn: LoginCopyappId: com.example.app
---
- runFlow: Login.yaml # <-- Run commands from "Login.yaml"
- tapOn: Profile
- assertVisible: "Name: Test User"CopyappId: com.example.app
---
- runFlow: Login.yaml # <-- Run commands from "Login.yaml"
- tapOn: Settings
- assertVisible: "Switch to dark mode"Flow files are a great way to abstract steps or create a reusable component. Be mindful during test Flow files help you reuse and abstract steps. Keep tests easy to follow so they stay maintainable.Pass environment variables to a subflowYou can pass variables to the subflow using the env parameter. These variables are accessible within the subflow.When to use inline subflowsInline subflows fit conditional logic or small groups of steps that don't need a separate file. Use a label so the step has a clear intent; otherwise, listing the commands directly is simpler.Run an inline FlowTo define a subflow in place, use the commands parameter instead of file. A label gives the step a clear name so you can see at a glance what it does. For example:You can also pass environment variables into an inline subflow:Cloud executionPass a workspace folder (not a single Flow file) so Maestro can upload dependent flows and a root config.yaml if present. Passing only a file relies on best-effort dependency collection and can result in Failed to parse file. Use named parameters. For example, if your flows and app are under myTestsFolder:Related contentLearn how to define parameters and set environment variables in Maestro Flows by accessing the Parameters and constants and  pages.PreviousretryNextrunScriptLast updated 10 days agoParametersUsage examplesCloud executionRelated contentCopy- runFlow: 
    file: anotherFlow.yaml
    env:
      MY_PARAMETER: "123"Copy- runFlow:
    label: Sort alphabetically
    commands:
      - tapOn:
          id: sort_icon
      - tapOn: algorithm
      - tapOn: A-Z
      - tapOn: ApplyCopy- runFlow:
    env:
      INNER_ENV: Inner Parameter
    commands:
      - inputText: ${INNER_ENV}Copymaestro cloud --app-file myApp.apk --flows ./myTestsFolder
