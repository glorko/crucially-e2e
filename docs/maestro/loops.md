Loops | Flows | Maestro DocsMaestro Docs⌘CtrlkAskIntroductionMaestro StudioMaestro CLIMaestro CloudFlowsAPI ReferenceExamplesResourcesGitBook AssistantWorking...Thinking...Good morningI'm here to help you with the docs.What is this page about?What should I read next?Can you give an example?⌘CtrliAI Based on your contextSendMaestro DocsMaestro Flows overviewFlow Control and LogicFlow control and logic overviewHow to use SelectorsNested flowsWait commandsLoopsConditionsParameters and constantsSpecify and start devicesHooksTest in different localesPermissionsDetect MaestroJavaScriptJavaScript overviewRun and debug JavaScriptManage data and statesMake HTTP requestsGenerate synthetic dataWorkspace ManagementWorkspace management overviewProject configurationDesign your test architectureTest discovery and tagsSequential executionTest reports and artifactsRecord your FlowAI test analysisPowered by GitBookOn this pageAskFlow Control and LogicLoopsRepeat actions using the repeat command for iterative test scenarios.Automating repetitive tasks is one of the primary benefits of end-to-end testing. Whether you are adding multiple items to a cart, deleting a list of messages, or performing bulk data entry, loops allow you to execute sequences of commands efficiently without duplicating code.In Maestro, loops are handled via the repeat command. This guide will teach you how to use fixed and conditional loops to create dynamic and resilient Flows.Loop strategiesMaestro offers three main ways to loop through commands. Choosing the right one depends on whether you know the exact iteration count or if the loop depends on the dynamic state of the UI.Fixed iterations (times)Use this when you have a specific, known number of actions to perform. This is ideal for stress-testing a specific interaction or creating a specific number of items.Copy# Add 5 items to a list
- repeat:
    times: 5
    commands:
      - tapOn: "Add Item"
      - tapOn: "Save"Conditional loops (while)Use this when you don't know the exact count, but you know the state that should stop the loop. This is useful for handling dynamic content that may vary between test runs, like pagination.Copy# Delete messages until the "Inbox Empty" text appears
- repeat:
    while:
      notVisible: "Your inbox is empty"
    commands:
      - tapOn: "Delete Message"
      - tapOn: "Confirm"UI stabilityIf your loop involves fast tapping or rapid screen changes, consider adding a waitForAnimationToEnd inside the commands list to ensure the UI is ready for the next iteration.The smart loopIt is a best practice to provide a safety net in automation. By combining times and while, you ensure that a loop terminates even if the expected UI state is never reached (e.g., due to a bug or network error).Suppose you want to dismiss all "Update" notifications, but you want to limit the test to 10 dismissals to prevent an infinite loop if the notifications keep regenerating. In the following example, the loop terminates if the notifications are gone or if it hits 10 attempts, protecting your test from hanging indefinitely.Use JavaScript for complex logicSometimes, a simple visibility check is not enough. You might need to loop based on a numeric value or a calculation. For this, you can use JavaScript expressions within the while parameter.Depending on how you are using JavaScript, you might need to initialize a variable before the loop. For example, if you are using a counter, you can use evalScript to set a starting value in the Maestro output object. After that, you can use the variable in the while condition.In the following example, the counter is initialized and then incremented on each iteration of the loop.Integrate nested Flows with loopsYou can combine nested Flows with loops when you need to perform a complex, multi-step sequence multiple times (e.g., creating five different user accounts or adding a variety of products to a cart). Instead of cluttering your main test with a long list of commands inside a loop, you can encapsulate the logic in a subflow and call it using runFlow within the repeat block.Suppose you need to add three different items to a shopping cart. By combining repeat with runFlow and env variables, you can create a clean, data-driven test. The main Flow can use JavaScript to define the data and then loop through it, while the subflow handles the mechanics of finding and adding an item.Main FlowSubflowNext stepsNow that you understand how to use loops in your flows, learn how to use conditional execution or explore all the possibilities of using JavaScript to create tests.PreviousWait commandsNextConditionsLast updated 1 month agoLoop strategiesUse JavaScript for complex logicIntegrate nested Flows with loopsNext stepsCopy- repeat:
    times: 10
    while:
      visible: "Update available"
    commands:
      - tapOn: "Dismiss"
      - assertNotVisible: "Dismiss" # Ensure it disappears before next loopCopy- evalScript: ${output.attempt = 0}
- repeat:
    while:
      true: ${output.attempt < 3}
    commands:
      - tapOn: "Refresh Data"
      # Increment the counter after each attempt
      - evalScript: ${output.attempt++}CopyappId: com.example.shop
---
- launchApp
- evalScript: ${output.items = ["Headphones", "Charger", "Phone Case"]}
- evalScript: ${output.index = 0}

- repeat:
    while:
      true: ${output.index < output.items.length}
    commands:
      - runFlow:
          file: subflows/add_item.yaml
          env:
            PRODUCT_NAME: ${output.items[output.index]}
      - evalScript: ${output.index++}

- tapOn: "Cart"
- assertVisible: "3 Items"Copy# subflows/add_item.yaml
- tapOn: "Search"
- inputText: ${PRODUCT_NAME}
- pressKey: Enter
- tapOn: "Add to Cart"
- tapOn: "Back to Home"
