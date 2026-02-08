# Activity Diagram Workflow Specification
## Indoor Navigation System - User Navigation Flow

---

## 🎯 Diagram Scope
This activity diagram models the **complete user journey** from app launch to receiving navigation instructions in the Indoor Navigation System.

---

## 🏊 Swimlane Structure

### Swimlane 1: User
**Represents**: End user interactions and decisions  
**Color**: Light Blue (#E3F2FD)

### Swimlane 2: UI Layer  
**Represents**: Flutter presentation layer (Widgets, Screens)  
**Color**: Light Green (#E8F5E9)

### Swimlane 3: Business Logic
**Represents**: Core services (Pathfinding, State Management)  
**Color**: Light Yellow (#FFF9C4)

### Swimlane 4: Firebase
**Represents**: Backend services (Firestore, Authentication)  
**Color**: Light Orange (#FFE0B2)

---

## 📊 Complete Activity Flow

### Phase 1: Authentication

```
[Initial Node] (User)
    ↓
[Open App] (User)
    ↓
[Display Login Screen] (UI Layer)
    ↓
[Enter Credentials] (User)
    ↓
[Validate Credentials] (Business Logic)
    ↓
[Authenticate User] (Firebase)
    ↓
◇ [Valid Credentials?] (Business Logic)
    ├─[No]→ [Display Error Message] (UI Layer) → [Display Login Screen] (loop back)
    └─[Yes]→ Continue to Phase 2
```

### Phase 2: Home Screen & Building Selection

```
[Display Home Screen] (UI Layer)
    ↓
[Select Building] (User)
    ↓
[Fetch Building Data] (Firebase)
    ↓
[Display Trip Planner Widget] (UI Layer)
```

### Phase 3: Location Selection

```
[Choose Start Location] (User)
    ↓
[Display Location Search Dialog] (UI Layer)
    ↓
[Select Floor] (User)
    ↓
[Fetch Floor Nodes] (Firebase)
    ↓
[Choose End Location] (User)
    ↓
[Display Location Search Dialog] (UI Layer)
```

### Phase 4: Path Calculation (Core Logic)

```
[Load Map Data] (Business Logic)
    ↓
━━━ [Fork Node] ━━━ (Parallel data fetching)
    ├→ [Fetch Building Data] (Firebase)
    ├→ [Fetch Floor Nodes] (Firebase)
    └→ [Fetch Graph Edges] (Firebase)
━━━ [Join Node] ━━━
    ↓
[Execute A* Pathfinding] (Business Logic)
    ↓
◇ [Path Found?] (Business Logic)
    ├─[No]→ [Display Error Message] (UI Layer) → [Display Trip Planner Widget] (loop back)
    └─[Yes]→ Continue
        ↓
    ◇ [Same Floor?] (Business Logic)
        ├─[Yes]→ [Generate Step-by-Step Instructions] (Business Logic)
        └─[No]→ [Handle Multi-Floor Transitions] (Business Logic)
                    ↓
                [Generate Step-by-Step Instructions] (Business Logic)
```

### Phase 5: Navigation Display

```
[Generate Step-by-Step Instructions] (Business Logic)
    ↓
[Display Navigation Screen] (UI Layer)
    ↓
[View Navigation Instructions] (User)
    ↓
[Follow Directions] (User)
    ↓
[Final Node] (User)
```

---

## 🔀 Decision Points Detail

### Decision 1: Valid Credentials?
- **Location**: Business Logic swimlane
- **Guards**: 
  - `[Yes]` → Proceed to Home Screen
  - `[No]` → Display error, loop back to Login Screen
- **Logic**: Checks Firebase Auth response

### Decision 2: Path Found?
- **Location**: Business Logic swimlane  
- **Guards**:
  - `[Yes]` → Check if same floor
  - `[No]` → Display "No path available" error
- **Logic**: A* algorithm returns null if no path exists

### Decision 3: Same Floor?
- **Location**: Business Logic swimlane
- **Guards**:
  - `[Yes]` → Direct instruction generation
  - `[No]` → Handle elevator/stairs transitions
- **Logic**: Compares start and end floor IDs

---

## 🔄 Parallel Activities (Fork/Join)

### Parallel Data Fetching
**Fork Point**: Before pathfinding execution  
**Parallel Branches**:
1. Fetch Building Data (building metadata)
2. Fetch Floor Nodes (rooms, corridors)  
3. Fetch Graph Edges (connections between nodes)

**Join Point**: After all data loaded  
**Next**: Execute A* Pathfinding

**Rationale**: Optimize loading time by fetching data concurrently

---

## 📦 Object Nodes (Data Flow)

### Object 1: User Credentials
- **Type**: `{email: String, password: String}`
- **Flow**: User → Validate Credentials → Firebase

### Object 2: Map Graph
- **Type**: `Graph<Node, Edge>`
- **Flow**: Firebase → Business Logic → A* Algorithm

### Object 3: Path Result
- **Type**: `List<Node>`
- **Flow**: A* Algorithm → Instruction Generator

### Object 4: Navigation Instructions
- **Type**: `List<NavigationStep>`
- **Flow**: Business Logic → UI Layer → User

---

## ⚠️ Exception Handling

### Exception 1: Network Failure
- **Trigger**: Firebase fetch timeout
- **Handler**: Display "Check internet connection" message
- **Recovery**: Retry button → Loop back to data fetch

### Exception 2: Invalid Location
- **Trigger**: User selects non-existent node
- **Handler**: Display "Location not found" error
- **Recovery**: Clear selection → Reopen search dialog

### Exception 3: Session Timeout
- **Trigger**: Firebase Auth token expires
- **Handler**: Auto-logout
- **Recovery**: Redirect to Login Screen

---

## 🎨 Visual Formatting Guide

### Node Sizing
- **Actions**: 120px width × 40px height
- **Decisions**: 80px × 80px (diamond)
- **Fork/Join**: 200px width × 8px height (bar)

### Spacing
- **Vertical spacing**: 60px between nodes
- **Horizontal spacing**: 40px between swimlanes
- **Swimlane width**: 250px each

### Arrow Styles
- **Control Flow**: Solid line with arrow
- **Object Flow**: Dashed line with arrow
- **Guard Labels**: 12pt font, bold, in brackets

### Color Scheme
```
User Swimlane:       #E3F2FD (Light Blue)
UI Layer:            #E8F5E9 (Light Green)  
Business Logic:      #FFF9C4 (Light Yellow)
Firebase:            #FFE0B2 (Light Orange)

Actions:             White background, black text
Decisions:           Light gray background
Fork/Join:           Black fill
Initial/Final:       Black fill
```

---

## 📝 Labels and Naming

### Action Labels
- Use **verb + noun** format
- Examples:
  - ✅ "Execute A* Pathfinding"
  - ✅ "Display Navigation Screen"
  - ❌ "Pathfinding" (missing verb)
  - ❌ "Show screen" (too vague)

### Decision Labels
- Use **questions** ending with `?`
- Examples:
  - ✅ "Valid Credentials?"
  - ✅ "Path Found?"
  - ❌ "Check credentials" (not a question)

### Guard Labels
- Use **brackets** with condition
- Examples:
  - ✅ `[Yes]`
  - ✅ `[No]`
  - ✅ `[Same Floor]`
  - ✅ `[Different Floor]`

---

## 🔍 Key Annotations

Add these **notes** to the diagram:

### Note 1: A* Algorithm
```
Position: Near "Execute A* Pathfinding" action
Text: "A* Algorithm calculates shortest path using:
       - Heuristic: Euclidean distance
       - Cost: Edge weights (distance)
       - Supports multi-floor navigation"
```

### Note 2: Firebase Integration
```
Position: Near Firebase swimlane
Text: "Cloud Firestore provides real-time map data:
       - Buildings, Floors, Nodes, Edges
       - Cached locally for offline support"
```

### Note 3: State Management
```
Position: Near UI Layer
Text: "Riverpod manages state:
       - Selected locations
       - Calculated path
       - Navigation progress"
```

---

## ✅ Validation Checklist

Before finalizing, verify:

- [ ] All 4 swimlanes are present and labeled
- [ ] Initial node is at the top
- [ ] Final node is at the bottom
- [ ] All decision nodes have 2+ outgoing flows
- [ ] All decision flows have guard labels
- [ ] Fork and Join nodes are paired
- [ ] No orphaned nodes (all connected)
- [ ] Flow direction is top-to-bottom or left-to-right
- [ ] Error handling paths are included
- [ ] Multi-floor logic is visible
- [ ] Object nodes show data flow
- [ ] Notes explain complex logic

---

## 📏 Diagram Dimensions

**Recommended Canvas Size**: 1200px × 1800px  
**Export Resolution**: 300 DPI  
**File Format**: PNG (for documentation), MDJ (StarUML project)

---

## 🚀 Advanced Features (Optional)

### Expansion Regions
Use for iterative processes:
- **Iterative**: Processing each navigation step
- **Parallel**: Rendering multiple floor maps

### Signals
- **Send Signal**: "Navigation Started"
- **Accept Signal**: "User Location Updated"

### Time Events
- **Accept Time Event**: "Session Timeout (30 min)"
- **Accept Time Event**: "Refresh Map Data (5 min)"

---

## 📚 References

- **A* Pathfinding**: `lib/core/services/pathfinding_service.dart`
- **Trip Planner UI**: `lib/features/navigation/presentation/widgets/trip_planner_widget.dart`
- **Firebase Repository**: `lib/features/admin_map/data/repositories/firebase_map_repository.dart`
- **Authentication**: `lib/features/auth/domain/usecases/login_usecase.dart`

---

## 💡 Tips for StarUML

1. **Use Auto-Layout**: Format → Layout → Auto Layout (Hierarchical)
2. **Align Elements**: Select multiple → Format → Align → Align Center
3. **Distribute Evenly**: Format → Align → Distribute Vertically
4. **Group Related Nodes**: Right-click → Group
5. **Lock Swimlanes**: Right-click → Lock to prevent accidental moves

---

**This specification provides the complete blueprint for your Activity Diagram!** 🎯
