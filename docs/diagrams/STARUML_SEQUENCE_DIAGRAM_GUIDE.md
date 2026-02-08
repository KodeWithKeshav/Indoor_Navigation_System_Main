# StarUML Sequence Diagram Guide - Indoor Navigation System

## 📋 Overview
This guide will help you create a comprehensive **Sequence Diagram** for the Indoor Navigation System using StarUML. The diagram will illustrate the interaction flow between objects over time for a specific scenario.

---

## 🎯 What We'll Model

**Scenario: User Navigates from Room A to Room B**

**Participants (Objects):**
- User (Actor)
- LoginScreen (UI)
- HomeScreen (UI)
- TripPlannerWidget (UI)
- LocationSearchDialog (UI)
- PathfindingService (Business Logic)
- FirebaseRepository (Data)
- NavigationScreen (UI)

**Interaction Flow:**
1. User logs in
2. User selects building and floor
3. User chooses start and end locations
4. System calculates path using A*
5. System displays navigation instructions

---

## 🛠 Prerequisites

1. **StarUML installed** from https://staruml.io/
2. **Understanding of system flow**
3. **Basic UML Sequence Diagram concepts**

---

## 📐 Step-by-Step Instructions

### Step 1: Create New Sequence Diagram
1. Open **StarUML**
2. In **Model Explorer**, right-click on **Model**
3. Select **Add Diagram → Sequence Diagram**
4. Rename to `UserNavigationSequenceDiagram`

---

### Step 2: Add Lifelines (Participants)

Lifelines represent objects/actors in the interaction.

#### Lifeline 1: User (Actor)
1. Click **Lifeline** tool
2. Place at far left of canvas
3. Name it `:User`
4. Right-click → Properties → Set `type` to `Actor`

**Note**: Actor lifelines use stick figure icon

#### Lifeline 2: LoginScreen
1. Add **Lifeline**
2. Name it `:LoginScreen`
3. Type: `UI Component`

#### Lifeline 3: FirebaseAuth
1. Add **Lifeline**
2. Name it `:FirebaseAuth`
3. Type: `Service`

#### Lifeline 4: HomeScreen
1. Add **Lifeline**
2. Name it `:HomeScreen`

#### Lifeline 5: TripPlannerWidget
1. Add **Lifeline**
2. Name it `:TripPlannerWidget`

#### Lifeline 6: LocationSearchDialog
1. Add **Lifeline**
2. Name it `:LocationSearchDialog`

#### Lifeline 7: FirebaseRepository
1. Add **Lifeline**
2. Name it `:FirebaseRepository`

#### Lifeline 8: PathfindingService
1. Add **Lifeline**
2. Name it `:PathfindingService`

#### Lifeline 9: NavigationScreen
1. Add **Lifeline**
2. Name it `:NavigationScreen`

**Arrange left to right**: User → UI → Services → Data

---

### Step 3: Add Messages (Interactions)

Messages flow between lifelines, showing method calls and responses.

#### Phase 1: Authentication

**Message 1: User → LoginScreen**
1. Click **Message** tool (solid arrow)
2. Draw from `User` to `LoginScreen`
3. Label: `1: enterCredentials(email, password)`

**Message 2: LoginScreen → FirebaseAuth**
1. Draw **Message** from `LoginScreen` to `FirebaseAuth`
2. Label: `2: authenticate(email, password)`

**Message 3: FirebaseAuth → LoginScreen (Return)**
1. Click **Return Message** tool (dashed arrow)
2. Draw from `FirebaseAuth` to `LoginScreen`
3. Label: `3: return authToken`

**Message 4: LoginScreen → HomeScreen**
1. Draw **Message** from `LoginScreen` to `HomeScreen`
2. Label: `4: navigateToHome()`

---

#### Phase 2: Building Selection

**Message 5: User → HomeScreen**
1. Draw from `User` to `HomeScreen`
2. Label: `5: selectBuilding(buildingId)`

**Message 6: HomeScreen → TripPlannerWidget**
1. Draw from `HomeScreen` to `TripPlannerWidget`
2. Label: `6: showTripPlanner(buildingId)`

---

#### Phase 3: Location Selection

**Message 7: User → TripPlannerWidget**
1. Draw from `User` to `TripPlannerWidget`
2. Label: `7: clickStartLocation()`

**Message 8: TripPlannerWidget → LocationSearchDialog**
1. Draw from `TripPlannerWidget` to `LocationSearchDialog`
2. Label: `8: openSearchDialog(floorId)`

**Message 9: LocationSearchDialog → FirebaseRepository**
1. Draw from `LocationSearchDialog` to `FirebaseRepository`
2. Label: `9: fetchRooms(floorId)`

**Message 10: FirebaseRepository → LocationSearchDialog (Return)**
1. Draw **Return** from `FirebaseRepository` to `LocationSearchDialog`
2. Label: `10: return List<Room>`

**Message 11: User → LocationSearchDialog**
1. Draw from `User` to `LocationSearchDialog`
2. Label: `11: selectRoom(roomId)`

**Message 12: LocationSearchDialog → TripPlannerWidget (Return)**
1. Draw **Return** from `LocationSearchDialog` to `TripPlannerWidget`
2. Label: `12: return selectedRoom`

**Repeat for End Location** (Messages 13-18)

---

#### Phase 4: Path Calculation

**Message 19: User → TripPlannerWidget**
1. Draw from `User` to `TripPlannerWidget`
2. Label: `19: clickNavigate()`

**Message 20: TripPlannerWidget → FirebaseRepository**
1. Draw from `TripPlannerWidget` to `FirebaseRepository`
2. Label: `20: fetchMapGraph(buildingId)`

**Message 21: FirebaseRepository → TripPlannerWidget (Return)**
1. Draw **Return**
2. Label: `21: return (rooms, corridors)`

**Message 22: TripPlannerWidget → PathfindingService**
1. Draw from `TripPlannerWidget` to `PathfindingService`
2. Label: `22: findPath(startId, endId, rooms, corridors)`

**Add Activation Box** (shows processing):
1. Right-click on `PathfindingService` lifeline at message 22
2. Select **Add → Activation**
3. Extend activation box vertically to show processing time

**Message 23: PathfindingService → PathfindingService (Self-call)**
1. Draw **Message** from `PathfindingService` to itself
2. Label: `23: executeAStarAlgorithm()`

**Message 24: PathfindingService → TripPlannerWidget (Return)**
1. Draw **Return**
2. Label: `24: return pathNodes`

---

#### Phase 5: Navigation Display

**Message 25: TripPlannerWidget → NavigationScreen**
1. Draw from `TripPlannerWidget` to `NavigationScreen`
2. Label: `25: showNavigation(pathNodes)`

**Message 26: NavigationScreen → User**
1. Draw from `NavigationScreen` to `User`
2. Label: `26: displayInstructions()`

---

### Step 4: Add Combined Fragments (Optional)

Combined fragments show conditional logic, loops, etc.

#### Alt Fragment: Authentication Success/Failure

1. Click **Combined Fragment** tool
2. Select **alt** (alternative)
3. Draw around messages 2-4
4. Add **guard conditions**:
   - Top section: `[authentication successful]`
   - Bottom section: `[authentication failed]`
5. In bottom section, add:
   - Message: `FirebaseAuth → LoginScreen: return error`
   - Message: `LoginScreen → User: displayError()`

#### Loop Fragment: Fetch Multiple Floors

1. Add **Combined Fragment** → **loop**
2. Draw around message 9-10
3. Guard: `[for each floor in building]`

---

### Step 5: Add Notes

#### Note 1: A* Algorithm
```
Position: Near PathfindingService activation
Text: "A* Algorithm:
       1. Build graph from rooms and corridors
       2. Calculate heuristic (Euclidean distance)
       3. Find shortest path
       4. Handle multi-floor transitions"
```

#### Note 2: Firebase Caching
```
Position: Near FirebaseRepository
Text: "Map data is cached locally
       Reduces network calls
       Supports offline mode"
```

---

### Step 6: Format and Style

#### Lifeline Spacing
1. Ensure even spacing between lifelines (100-150px)
2. Arrange logically: User → UI → Logic → Data

#### Message Numbering
1. Number messages sequentially: 1, 2, 3, ...
2. Use sub-numbering for branches: 1.1, 1.2, etc.

#### Activation Boxes
1. Add activation boxes to show when objects are active
2. Right-click lifeline → Add → Activation
3. Extend vertically to cover processing time

#### Color Coding
1. **User messages**: Blue
2. **UI messages**: Green
3. **Service messages**: Yellow
4. **Data messages**: Orange

---

### Step 7: Export Diagram

1. **File → Export Diagram → PNG**
2. Resolution: **300 DPI**
3. Save as `SequenceDiagram.png` in `/docs/diagrams/`

---

## 🎨 Diagram Best Practices

### Visual Clarity
- **Left to right**: Arrange lifelines logically (Actor → UI → Logic → Data)
- **Top to bottom**: Time flows downward
- **Minimize crossing**: Rearrange lifelines to reduce arrow crossings
- **Use activations**: Show when objects are processing

### Naming Conventions
- **Lifelines**: `:ClassName` (colon prefix for instances)
- **Messages**: `methodName(parameters)`
- **Returns**: `return value` or just `return`
- **Guards**: `[condition]` in square brackets

### Message Types
- **Synchronous**: Solid arrow (waits for response)
- **Asynchronous**: Stick arrow (doesn't wait)
- **Return**: Dashed arrow (return value)
- **Self-call**: Arrow to same lifeline (internal method)

---

## 📊 Key Elements Reference

| Element | StarUML Tool | Purpose | Example |
|---------|-------------|---------|---------|
| **Lifeline** | Lifeline | Object/Actor | `:User`, `:LoginScreen` |
| **Message** | Message | Method call | `authenticate(email, password)` |
| **Return** | Return Message | Return value | `return authToken` |
| **Activation** | Activation | Processing time | Vertical box on lifeline |
| **Combined Fragment** | Combined Fragment | Logic (alt, loop, opt) | `[if authenticated]` |
| **Note** | Note | Explanation | Algorithm details |

---

## 🔍 Message Sequence Summary

```
1. User → LoginScreen: enterCredentials()
2. LoginScreen → FirebaseAuth: authenticate()
3. FirebaseAuth → LoginScreen: return authToken
4. LoginScreen → HomeScreen: navigateToHome()
5. User → HomeScreen: selectBuilding()
6. HomeScreen → TripPlannerWidget: showTripPlanner()
7. User → TripPlannerWidget: clickStartLocation()
8. TripPlannerWidget → LocationSearchDialog: openSearchDialog()
9. LocationSearchDialog → FirebaseRepository: fetchRooms()
10. FirebaseRepository → LocationSearchDialog: return List<Room>
11. User → LocationSearchDialog: selectRoom()
12. LocationSearchDialog → TripPlannerWidget: return selectedRoom
[Repeat 13-18 for end location]
19. User → TripPlannerWidget: clickNavigate()
20. TripPlannerWidget → FirebaseRepository: fetchMapGraph()
21. FirebaseRepository → TripPlannerWidget: return (rooms, corridors)
22. TripPlannerWidget → PathfindingService: findPath()
23. PathfindingService → PathfindingService: executeAStarAlgorithm()
24. PathfindingService → TripPlannerWidget: return pathNodes
25. TripPlannerWidget → NavigationScreen: showNavigation()
26. NavigationScreen → User: displayInstructions()
```

---

## ✅ Final Checklist

- [ ] All lifelines are added (User, UI, Services, Data)
- [ ] Lifelines are arranged logically (left to right)
- [ ] Messages are numbered sequentially
- [ ] Synchronous messages use solid arrows
- [ ] Return messages use dashed arrows
- [ ] Activation boxes show processing
- [ ] Combined fragments show conditional logic
- [ ] Notes explain complex interactions
- [ ] Diagram flows top to bottom (time)
- [ ] Color coding is applied
- [ ] Diagram is exported as PNG

---

## 💡 Quick Tips

1. **Focus on one scenario**: Don't try to show everything
2. **Keep it readable**: Don't overcrowd with too many lifelines
3. **Use fragments sparingly**: Only for important conditions/loops
4. **Number messages**: Helps follow the flow
5. **Show key interactions**: Skip trivial getters/setters

---

## 🎓 Alternative Scenarios

You can create additional sequence diagrams for:
- **Admin Creates Building**: Admin → UI → Firebase
- **Multi-Floor Navigation**: Handling elevator/stairs
- **Error Handling**: Network failure, invalid input
- **Accessibility Mode**: Alternative pathfinding

---

## 🎓 Learning Resources

- **StarUML Sequence**: https://docs.staruml.io/working-with-diagrams/sequence-diagram
- **UML Sequence**: https://www.uml-diagrams.org/sequence-diagrams.html

---

**Your Sequence Diagram will show the dynamic behavior of your system! ⏱️**
