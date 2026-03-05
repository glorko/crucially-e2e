State Selectors | API Reference | Maestro DocsMaestro Docs⌘CtrlkAskIntroductionMaestro StudioMaestro CLIMaestro CloudFlowsAPI ReferenceExamplesResourcesGitBook AssistantWorking...Thinking...Good afternoonI'm here to help you with the docs.What is this page about?What should I read next?Can you give an example?⌘CtrliAI Based on your contextSendMaestro DocsCommands overviewCommands availableSelectorsCore SelectorsRelational SelectorsElement TraitsState SelectorsDimension matchersWorkspace configurationPowered by GitBookOn this pageAskSelectorsState SelectorsSelect elements by state: enabled, checked, focused, or selected properties.State Selectors allow you to filter UI elements based on their current functional or interactive status. These are primarily used to verify that an element is ready for interaction, has been correctly updated by a previous action, or to find a specific element among several identical ones (e.g., finding the selected tab in a navigation bar).OverviewAll state selectors accept a boolean value (true or false).SelectorDescriptionenabledMatches elements based on whether they are currently interactive or "grayed out."checkedMatches elements based on their toggle state (Checkboxes, Radio Buttons, Switches).focusedMatches the element that currently has keyboard input focus.selectedMatches elements currently marked as selected (often used for Tabs or Segmented Controls).Usage tipsState Selectors are most effective when combined with Core Selectors. For example, finding a specific button that is also enabled: tapOn: { text: "Next", enabled: true }.enabledThe enabled selector is essential for ensuring that an app’s logic is functioning correctly. For example, a "Submit" button should remain disabled (enabled: false) until all required fields are filled.Copy# Assert that the login button is disabled initially
- assertVisible:
    id: login_button
    enabled: false

# Tap the button once it becomes active
- tapOn:
    id: login_button
    enabled: truecheckedThis selector is specifically for elements that hold a binary state, such as checkboxes, radio buttons, and switches.focusedThe focused selector identifies the element that is currently active for text input. This is useful for verifying that tapOn correctly placed the cursor in the right field or that an app automatically focuses the first input field on a form.selectedWhile similar to checked, selected is typically used for navigation elements like tabs, segmented controls, or specific items in a list that have been highlighted.PreviousElement TraitsNextDimension matchersLast updated 9 days agoOverviewenabledcheckedfocusedselectedCopy# Find the checkbox that is currently checked
- assertVisible:
    id: "remember_me_checkbox"
    checked: true

# Ensure a switch is turned off
- assertVisible:
    id: notifications_switch
    checked: falseCopy# Verify that the 'Search' input field has focus
- assertVisible:
    id: search_input
    focused: trueCopy# Find the 'Profile' tab only if it is the currently selected one
- tapOn:
    text: Profile
    selected: true
