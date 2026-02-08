# StarUML Activity Diagram Guide - Indoor Navigation System

## 📋 Overview
This guide will help you create a comprehensive **Activity Diagram** for the Indoor Navigation System using StarUML. The diagram will illustrate the user navigation workflow from authentication to receiving step-by-step directions.

---

## 🎯 What We'll Model

**Primary Flow: User Navigation Journey**
- User Authentication (Login)
- Building/Floor Selection
- Start/End Location Selection
- Path Calculation (A* Algorithm)
- Navigation Instructions Display
- Multi-floor Navigation Handling

---

## 🛠 Prerequisites

1. **Download StarUML**: [https://staruml.io/](https://staruml.io/)
2. **Install StarUML** on your system
3. **Familiarize yourself** with basic UML Activity Diagram concepts

---

## 📐 Step-by-Step Instructions

### Step 1: Create New Project
1. Open **StarUML**
2. Click **File → New**
3. Select **UML Standard** from templates
4. Click **OK**

### Step 2: Add Activity Diagram
1. In the **Model Explorer** (left panel), right-click on **Model**
2. Select **Add Diagram → Activity Diagram**
3. Rename it to `UserNavigationActivityDiagram`

### Step 3: Set Up Swimlanes (Partitions)

Activity diagrams for systems with multiple actors/components work best with **swimlanes**. We'll create 4 swimlanes:

1. Click the **Partition** tool in the toolbar (looks like vertical bars)
2. Draw a partition on the canvas
3. Double-click to rename it to **"User"**
4. Repeat to create these partitions:
   - **User** (User actions)
   - **UI Layer** (Flutter UI components)
   - **Business Logic** (Pathfinding Service)
   - **Firebase** (Backend data)

**Layout**: Arrange them vertically or horizontally based on preference.

---

### Step 4: Build the Activity Flow

Now we'll add the activity nodes. Use these StarUML elements:

#### 🟢 Initial Node (Start)
1. Click **Initial Node** tool (filled black circle)
2. Place it in the **User** swimlane at the top

#### 📦 Actions (Activity Nodes)

Add these **Action** nodes in sequence. Click the **Action** tool and place them in appropriate swimlanes:

**In User Swimlane:**
- `Open App`
- `Enter Credentials`
- `Select Building`
- `Select Floor`
- `Choose Start Location`
- `Choose End Location`
- `View Navigation Instructions`
- `Follow Directions`

**In UI Layer Swimlane:**
- `Display Login Screen`
- `Display Home Screen`
- `Display Trip Planner Widget`
- `Display Location Search Dialog`
- `Display Navigation Screen`

**In Business Logic Swimlane:**
- `Validate Credentials`
- `Load Map Data`
- `Execute A* Pathfinding`
- `Generate Step-by-Step Instructions`
- `Handle Multi-Floor Transitions`

**In Firebase Swimlane:**
- `Authenticate User`
- `Fetch Building Data`
- `Fetch Floor Nodes`
- `Fetch Graph Edges`

#### 🔶 Decision Nodes (Diamonds)

Add **Decision Node** for branching logic:

1. Click **Decision Node** tool (diamond shape)
2. Add these decisions:
   - `Valid Credentials?` (after Validate Credentials)
   - `Same Floor?` (after path calculation)
   - `Path Found?` (after A* execution)

#### 🔀 Merge Nodes

Add **Merge Node** to combine flows back together where needed.

#### 🔴 Final Node (End)

1. Click **Final Node** tool (circle with filled circle inside)
2. Place at the end of the flow in **User** swimlane

---

### Step 5: Connect Activities with Control Flows

1. Click **Control Flow** tool (arrow)
2. Connect activities in logical sequence:

```
Initial Node → Open App → Display Login Screen → Enter Credentials 
→ Validate Credentials → Authenticate User → [Valid Credentials?]

[Valid Credentials? = Yes] → Display Home Screen → Select Building 
→ Fetch Building Data → Display Trip Planner Widget → Choose Start Location
→ Display Location Search Dialog → Choose End Location → Execute A* Pathfinding
→ [Path Found?]

[Path Found? = Yes] → [Same Floor?]
[Same Floor? = Yes] → Generate Step-by-Step Instructions
[Same Floor? = No] → Handle Multi-Floor Transitions → Generate Step-by-Step Instructions

Generate Step-by-Step Instructions → Display Navigation Screen 
→ View Navigation Instructions → Follow Directions → Final Node

[Valid Credentials? = No] → Display Login Screen (loop back)
[Path Found? = No] → Display Error Message → Display Trip Planner Widget (loop back)
```

3. **Label decision branches**: Double-click on control flows from decision nodes and add guards like `[Yes]`, `[No]`, `[Valid]`, `[Invalid]`

---

### Step 6: Add Fork/Join Nodes (Optional - for Parallel Activities)

If you want to show parallel data fetching:

1. Add **Fork Node** (thick horizontal bar) before fetching data
2. Add parallel flows for:
   - Fetch Building Data
   - Fetch Floor Nodes  
   - Fetch Graph Edges
3. Add **Join Node** (thick horizontal bar) to synchronize before pathfinding

---

### Step 7: Enhance Diagram Readability

#### Add Notes
1. Click **Note** tool
2. Add explanatory notes:
   - "A* Algorithm calculates shortest path considering multi-floor transitions"
   - "Firebase Firestore provides real-time map data"
   - "Riverpod manages state across UI components"

#### Format Elements
1. Select elements and use **Format → Font** to adjust text size
2. Use **Format → Fill Color** to color-code swimlanes:
   - User: Light Blue
   - UI Layer: Light Green
   - Business Logic: Light Yellow
   - Firebase: Light Orange

#### Align Elements
1. Select multiple elements
2. Use **Format → Align** to align vertically/horizontally
3. Use **Format → Layout → Auto Layout** for automatic arrangement

---

### Step 8: Add Object Nodes (Optional - for Data Flow)

To show data being passed:

1. Click **Object Node** tool (rectangle)
2. Add data objects like:
   - `User Credentials`
   - `Map Graph`
   - `Path Result`
   - `Navigation Instructions`
3. Connect with **Object Flow** arrows

---

### Step 9: Review and Refine

**Checklist:**
- ✅ All major user actions included
- ✅ Decision points clearly marked with guards
- ✅ Swimlanes properly labeled
- ✅ Flow is logical and complete
- ✅ Error handling paths included
- ✅ Multi-floor navigation logic shown

---

### Step 10: Export Diagram

1. Click **File → Export Diagram**
2. Choose **PNG** format
3. Set resolution to **300 DPI** for clarity
4. Save as `ActivityDiagram.png` in `/docs/diagrams/`

**Alternative Export:**
- **File → Export Diagram → SVG** for vector graphics
- **File → Print to PDF** for documentation

---

## 🎨 Diagram Best Practices

### Visual Clarity
- **Keep swimlanes organized**: Don't cross swimlane boundaries unnecessarily
- **Use consistent spacing**: Align nodes vertically/horizontally
- **Minimize crossing arrows**: Rearrange nodes to reduce visual clutter
- **Group related activities**: Keep related actions close together

### Naming Conventions
- **Actions**: Use verb phrases (`Execute A* Pathfinding`, `Display Home Screen`)
- **Decisions**: Use questions (`Valid Credentials?`, `Path Found?`)
- **Guards**: Use brackets (`[Yes]`, `[No]`, `[Same Floor]`)

### Color Coding
- **User actions**: Blue tones
- **System processes**: Green tones  
- **Data operations**: Yellow tones
- **External services**: Orange tones

---

## 📊 Key Elements Reference

| Element | StarUML Tool | Purpose | Example |
|---------|-------------|---------|---------|
| **Initial Node** | Black circle | Start of flow | Beginning of user journey |
| **Action** | Rounded rectangle | Activity/Task | "Execute A* Pathfinding" |
| **Decision** | Diamond | Conditional branch | "Valid Credentials?" |
| **Merge** | Diamond | Combine flows | After error handling |
| **Fork** | Thick bar | Split into parallel | Parallel data fetching |
| **Join** | Thick bar | Synchronize parallel | Wait for all data loaded |
| **Final Node** | Bull's eye | End of flow | User completes navigation |
| **Partition** | Swimlane | Actor/Component | "User", "Firebase" |
| **Control Flow** | Arrow | Sequence | Action to action |
| **Object Node** | Rectangle | Data object | "Map Graph" |

---

## 🔍 Example Flow Snippet

Here's a detailed example of one section:

```
[User Swimlane]
Choose Start Location → Choose End Location

[UI Layer Swimlane]  
Display Location Search Dialog (receives input from user actions)

[Business Logic Swimlane]
Execute A* Pathfinding → [Path Found?]
  → [Yes] → [Same Floor?]
      → [Yes] → Generate Step-by-Step Instructions
      → [No] → Handle Multi-Floor Transitions → Generate Step-by-Step Instructions
  → [No] → Generate Error Message

[Firebase Swimlane]
(Fetch Graph Edges happens before pathfinding)
```

---

## 🚀 Advanced Tips

### 1. **Show Exception Handling**
Add **Exception Handler** regions for error scenarios:
- Network failure during Firebase fetch
- Invalid location selection
- No path found between locations

### 2. **Add Time Events**
Use **Accept Time Event** nodes for:
- Session timeout
- Real-time location updates

### 3. **Include Signals**
Use **Send Signal** / **Accept Signal** for:
- User notifications
- Navigation updates

### 4. **Expand Regions**
Use **Expansion Region** for iterative processes:
- Processing each step in navigation instructions
- Rendering multiple floor maps

---

## 📝 Documentation Tips

After creating the diagram:

1. **Add to README.md**:
   ```markdown
   ## UML Diagrams
   - [Activity Diagram](docs/diagrams/ActivityDiagram.png) - User Navigation Flow
   ```

2. **Create Description Document**:
   Write a separate `ActivityDiagram_Description.md` explaining:
   - Purpose of the diagram
   - Key decision points
   - Multi-floor navigation logic
   - Error handling strategies

3. **Version Control**:
   - Save StarUML project file (`.mdj`) in `/docs/diagrams/`
   - Commit both `.mdj` and exported `.png`

---

## ✅ Final Checklist

Before submitting:

- [ ] Diagram shows complete user navigation flow
- [ ] All swimlanes are clearly labeled
- [ ] Decision nodes have guard conditions
- [ ] Error handling paths are included
- [ ] Multi-floor navigation logic is visible
- [ ] Diagram is exported as high-resolution PNG
- [ ] StarUML project file is saved
- [ ] Diagram is referenced in main README.md

---

## 🎓 Learning Resources

- **StarUML Documentation**: [https://docs.staruml.io/](https://docs.staruml.io/)
- **UML Activity Diagrams**: [https://www.uml-diagrams.org/activity-diagrams.html](https://www.uml-diagrams.org/activity-diagrams.html)
- **Best Practices**: Focus on showing the flow of control, not implementation details

---

## 💡 Need Help?

If you encounter issues:
1. Check StarUML's built-in examples (**File → Open Example**)
2. Review UML 2.5 specification for activity diagrams
3. Ensure you're using **Activity Diagram** not **State Machine Diagram**

---

**Good luck building your Activity Diagram! 🚀**
