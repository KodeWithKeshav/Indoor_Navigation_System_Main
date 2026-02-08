# EPIC 1: Indoor Map Data Setup & Management

## User Story 1.1
As a system administrator, I want to add buildings to digitally represent campus structure.

- [x] 1.1.1 Design the building data schema with unique identifiers.
- [x] 1.1.2 Create an interface to input building details.
- [x] 1.1.3 Validate and store building data in the system.

## User Story 1.2
As a system administrator, I want to define floors to support multi-floor navigation.

- [x] 1.2.1 Link floors to their corresponding building IDs.
- [x] 1.2.2 Validate floor numbering and hierarchy rules.
- [x] 1.2.3 Store floor data and update building mappings.

## User Story 1.3
As a system administrator, I want to add rooms for precise indoor location selection.

- [x] 1.3.1 Generate unique room IDs and assign them to floors.
- [x] 1.3.2 Validate room uniqueness within each floor.
- [x] 1.3.3 Save room metadata to the location database.

## User Story 1.4
As a system administrator, I want to define corridors to establish indoor connectivity.

- [x] 1.4.1 Identify rooms that should be connected by corridors.
- [x] 1.4.2 Create bidirectional corridor links between rooms.
- [x] 1.4.3 Update the navigation graph with corridor paths.

## User Story 1.5
As a system administrator, I want to define stairs for vertical floor movement.

- [x] 1.5.1 Identify stair locations on each relevant floor.
- [x] 1.5.2 Link stair nodes across multiple floors.
- [x] 1.5.3 Store stair connections in the navigation graph.

## User Story 1.6
As a system administrator, I want to define elevators for accessible vertical navigation.

- [x] 1.6.1 Identify elevator nodes within buildings.
- [x] 1.6.2 Connect elevator nodes to supported floors.
- [x] 1.6.3 Store elevator data with accessibility attributes.

## User Story 1.7
As a system administrator, I want to tag accessibility features to enable inclusive routing.

- [x] 1.7.1 Define accessibility attributes for map entities.
- [x] 1.7.2 Attach accessibility tags to rooms and paths.
- [x] 1.7.3 Save accessibility metadata for routing logic.

## User Story 1.8
As a system administrator, I want to edit map data to reflect layout changes.

- [x] 1.8.1 Enable selection and modification of map entities.
- [x] 1.8.2 Revalidate connectivity after data changes.
- [x] 1.8.3 Save updated map data to the system.

## User Story 1.9
As a system administrator, I want to remove outdated locations to maintain map accuracy.

- [x] 1.9.1 Identify outdated or unused map entities.
- [x] 1.9.2 Remove associated links while preserving consistency.
- [x] 1.9.3 Update the navigation graph after deletion.

---

# EPIC 2: User Input for Location & Destination

## User Story 2.1
As a user, I want to select my starting building and room for navigation.

- [x] 2.1.1 Load and display a list of available buildings.
- [x] 2.1.2 Filter and display rooms based on the selected building.
- [x] 2.1.3 Capture and validate the user's starting coordinates.

## User Story 2.2
As a user, I want to select my destination building and room to plan routes.

- [x] 2.2.1 Provide a selection interface for destination buildings.
- [x] 2.2.2 Filter destination rooms to ensure they are reachable from the starting point.
- [x] 2.2.3 Store the destination ID for route calculation.

## User Story 2.3
As a user, I want a search bar to find specific locations by name quickly.

- [x] 2.3.1 Implement a real-time search algorithm for rooms and points of interest.
- [x] 2.3.2 Filter and display matching results as the user types.
- [x] 2.3.3 Allow direct selection from the search results to populate the destination field.

## User Story 2.4
As a user, I want locations grouped by floor to browse the campus hierarchy easily.

- [x] 2.4.1 Organize map entities into a nested data structure (Building > Floor > Room).
- [x] 2.4.2 Design a grouped UI components to represent the campus hierarchy.
- [x] 2.4.3 Implement "accordion" or "drill-down" navigation for location selection.

## User Story 2.5
As a user, I want to view recent locations to repeat frequent navigation paths faster.

- [x] 2.5.1 Cache the user's most recently selected starting points and destinations.
- [x] 2.5.2 Display a "Recent" or "Favorites" shortcut list on the main input screen.
- [x] 2.5.3 Manage the history limit to ensure only relevant, recent data is shown.

## User Story 2.6
As a user, I want to swap my start and end points for return trips.

- [x] 2.6.1 Create a "Swap" toggle button between the start and end input fields.
- [x] 2.6.2 Update the navigation logic to re-calculate the path in reverse.
- [x] 2.6.3 Re-validate the new path for one-way constraints or accessibility.

## User Story 2.7
As a user, I want the system to block invalid selections to avoid routing errors.

- [x] 2.7.1 Implement real-time validation to block "Start" and "End" being the same location.
- [ ] 2.7.2 Flag and hide rooms currently marked as "Out of Service" or "Closed."
- [x] 2.7.3 Display clear error messages when an invalid location combination is attempted.

## User Story 2.8
As a user, I want to edit my selected locations to correct any input mistakes.

- [x] 2.8.1 Enable "Clear" or "Edit" buttons on selected location tags.
- [x] 2.8.2 Reset the dependent UI states when a building selection is changed.
- [x] 2.8.3 Ensure the navigation graph clears previous path overlays upon modification.

## User Story 2.9
As a user, I want a trip summary before generating the final navigation path.

- [x] 2.9.1 Display a summary card showing the selected Start, End, and total floor distance.
- [x] 2.9.2 Provide a final "Get Directions" trigger to initiate the routing engine.
- [x] 2.9.3 Capture user confirmation to begin the turn-by-turn navigation process.

---

# EPIC 3: Route Computation & Path Optimization

## User Story 3.1
As a campus user, I want the system to compute the shortest route.

- [x] 3.1.1 Convert indoor map data into a graph structure.
- [x] 3.1.2 Apply a shortest-path algorithm on the graph.
- [x] 3.1.3 Generate and return the optimal route.

## User Story 3.2
As a campus user, I want routes to support navigation across multiple floors.

- [x] 3.2.1 Detect required floor transitions between nodes.
- [x] 3.2.2 Identify valid vertical connectors for transitions.
- [x] 3.2.3 Insert floor transitions into the computed route.

## User Story 3.3
As a campus user, I want stairs and elevators included for vertical movement.

- [x] 3.3.1 Integrate stairs and elevators into the routing graph.
- [x] 3.3.2 Validate availability of vertical connectors.
- [x] 3.3.3 Compute routes including vertical movement paths.

## User Story 3.4
As a campus user, I want disconnected paths avoided for reliable navigation.

- [x] 3.4.1 Check connectivity between start and destination nodes.
- [x] 3.4.2 Exclude unreachable or broken paths from routing.
- [x] 3.4.3 Handle failure cases when no valid route exists.

## User Story 3.5
As a campus user, I want routes recalculated when navigation inputs change.

- [x] 3.5.1 Detect changes in source, destination, or constraints.
- [x] 3.5.2 Trigger route recomputation automatically.
- [x] 3.5.3 Display the updated route without delay.

## User Story 3.6
As a campus user, I want routes optimized to minimize walking distance.

- [x] 3.6.1 Assign distance-based weights to graph edges.
- [x] 3.6.2 Optimize the routing cost function.
- [x] 3.6.3 Compute the minimal-distance path.

## User Story 3.7
As a campus user, I want same-floor navigation optimized for simplicity.

- [x] 3.7.1 Restrict routing to a single floor when possible.
- [x] 3.7.2 Compute direct paths without vertical transitions.
- [x] 3.7.3 Output a simplified same-floor route.

## User Story 3.8
As a campus user, I want step-by-step instructions for easy navigation.

- [x] 3.8.1 Break the route into sequential navigation steps.
- [x] 3.8.2 Generate clear textual instructions for each step.
- [x] 3.8.3 Display instructions in the correct order.

## User Story 3.9
As a campus user, I want clear start and end points displayed.

- [x] 3.9.1 Identify and mark the starting location node.
- [x] 3.9.2 Identify and mark the destination node.
- [x] 3.9.3 Display start and end markers on the route.

---

# EPIC 4: Accessibility & Inclusive Navigation

## User Story 4.1
As a user with mobility limitations, I want to avoid stairs.

- [x] 4.1.1 Identify stair nodes in the navigation graph.
- [x] 4.1.2 Mark stairs as restricted for accessibility routing.
- [x] 4.1.3 Exclude stair paths during route computation.

## User Story 4.2
As a user with accessibility needs, I want elevators prioritized for navigation.

- [ ] 4.2.1 Identify elevator connectors in the map data.
- [ ] 4.2.2 Assign higher priority weights to elevators.
- [ ] 4.2.3 Apply elevator preference during routing.

## User Story 4.3
As a user, I want to set accessibility preferences for personalized routing.

- [ ] 4.3.1 Design a user interface for selecting accessibility preferences.
- [ ] 4.3.2 Capture and store user preference settings.
- [ ] 4.3.3 Apply preferences to the routing logic.

## User Story 4.4
As a user, I want wheelchair-friendly routes for safe navigation.

- [ ] 4.4.1 Tag wheelchair-accessible paths and nodes.
- [ ] 4.4.2 Filter out non-compliant edges from routing.
- [ ] 4.4.3 Generate wheelchair-compliant routes.

## User Story 4.5
As a user, I want warnings for routes that are not accessible.

- [ ] 4.5.1 Detect accessibility conflicts in computed routes.
- [ ] 4.5.2 Generate appropriate warning messages.
- [ ] 4.5.3 Display alerts to the user.

## User Story 4.6
As a user, I want alternative routes when accessibility constraints exist.

- [ ] 4.6.1 Detect blocked or restricted paths.
- [ ] 4.6.2 Compute alternative accessible routes.
- [ ] 4.6.3 Display the best available option.

## User Story 4.7
As a user, I want accessibility features to be optional for navigation.

- [ ] 4.7.1 Provide a toggle to enable or disable accessibility mode.
- [ ] 4.7.2 Apply routing logic conditionally based on selection.
- [ ] 4.7.3 Maintain default routing behavior when disabled.

## User Story 4.8
As a user, I want accessible entrances included in route planning.

- [ ] 4.8.1 Identify and tag accessible building entrances.
- [ ] 4.8.2 Prioritize accessible entrance nodes in routing.
- [ ] 4.8.3 Integrate entrances into route computation.

## User Story 4.9
As a system, I want accessibility metadata stored for consistent inclusive routing.

- [ ] 4.9.1 Define a schema for accessibility metadata.
- [ ] 4.9.2 Store accessibility attributes with map entities.
- [ ] 4.9.3 Sync metadata with the routing engine.

---

# EPIC 5: User Interface & Experience Enhancements

## User Story 5.1
As a campus user, I want step-by-step navigation instructions for easy routing.

- [x] 5.1.1 Break the computed route into sequential steps.
- [x] 5.1.2 Format instructions in a clear, readable manner.
- [x] 5.1.3 Display ordered navigation steps on the interface.

## User Story 5.2
As a campus user, I want visual navigation cues for clear directions.

- [x] 5.2.1 Design visual indicators for navigation steps.
- [x] 5.2.2 Map visual cues to corresponding route steps.
- [x] 5.2.3 Render navigation visuals on the map view.

## User Story 5.3
As a campus user, I want icons for stairs and elevators.

- [x] 5.3.1 Design standard icons for stairs and elevators.
- [x] 5.3.2 Associate icons with relevant navigation steps.
- [x] 5.3.3 Display icons consistently within the UI.

## User Story 5.4
As a campus user, I want a high-contrast interface for readability.

- [x] 5.4.1 Design a high-contrast interface theme.
- [ ] 5.4.2 Provide a toggle to enable high-contrast mode.
- [x] 5.4.3 Apply theme styles across all navigation screens.

## User Story 5.5
As a campus user, I want adjustable font sizes for comfortable reading.

- [x] 5.5.1 Define selectable font size options.
- [x] 5.5.2 Implement dynamic font scaling across the UI.
- [x] 5.5.3 Apply font preferences to navigation content.

## User Story 5.6
As a campus user, I want voice-based navigation guidance for hands-free use.

- [ ] 5.6.1 Convert navigation instructions into speech output.
- [ ] 5.6.2 Synchronize voice guidance with route progress.
- [x] 5.6.3 Provide a toggle to enable or disable voice guidance.

## User Story 5.7
As a campus user, I want to replay navigation instructions when needed.

- [ ] 5.7.1 Store generated navigation instructions temporarily.
- [ ] 5.7.2 Provide controls to replay navigation guidance.
- [ ] 5.7.3 Restart guidance from the selected step.

## User Story 5.8
As a campus user, I want simple language directions for easy understanding.

- [x] 5.8.1 Simplify navigation text and remove technical terms.
- [x] 5.8.2 Use consistent, user-friendly phrasing.
- [x] 5.8.3 Validate instruction clarity through review.

## User Story 5.9
As a campus user, I want a consistent minimal interface for stress-free navigation.

- [x] 5.9.1 Define standard UI layout guidelines for navigation screens.
- [x] 5.9.2 Apply layouts consistently across the interface.
- [x] 5.9.3 Reduce visual clutter by prioritizing essential information.
