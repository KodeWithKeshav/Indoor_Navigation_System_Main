# StarUML Activity Diagram - Quick Reference Card

## 🎯 Your Mission
Create an Activity Diagram showing the **User Navigation Flow** in your Indoor Navigation System.

---

## 📋 Quick Start (5 Steps)

### 1️⃣ Open StarUML
- Download from: https://staruml.io/
- File → New → UML Standard

### 2️⃣ Create Activity Diagram
- Right-click "Model" → Add Diagram → Activity Diagram
- Name it: `UserNavigationActivityDiagram`

### 3️⃣ Add 4 Swimlanes (Partitions)
Click Partition tool, create these lanes:
- **User** (Light Blue)
- **UI Layer** (Light Green)
- **Business Logic** (Light Yellow)
- **Firebase** (Light Orange)

### 4️⃣ Build the Flow
Use these tools from the toolbar:

| Tool | What to Add |
|------|-------------|
| **Initial Node** (●) | Start point in User lane |
| **Action** (rounded box) | Activities like "Open App", "Execute A* Pathfinding" |
| **Decision** (◇) | "Valid Credentials?", "Path Found?", "Same Floor?" |
| **Fork/Join** (━━━) | Parallel data fetching |
| **Control Flow** (→) | Connect everything |
| **Final Node** (◉) | End point in User lane |

### 5️⃣ Export
- File → Export Diagram → PNG
- Resolution: 300 DPI
- Save as: `ActivityDiagram.png` in `/docs/diagrams/`

---

## 🔑 Key Activities to Include

### User Swimlane
```
● → Open App → Enter Credentials → Select Building 
→ Choose Start Location → Choose End Location 
→ View Navigation Instructions → Follow Directions → ◉
```

### UI Layer
```
Display Login Screen → Display Home Screen 
→ Display Trip Planner Widget → Display Location Search Dialog 
→ Display Navigation Screen
```

### Business Logic
```
Validate Credentials → Load Map Data → Execute A* Pathfinding 
→ Handle Multi-Floor Transitions → Generate Step-by-Step Instructions
```

### Firebase
```
Authenticate User → Fetch Building Data → Fetch Floor Nodes 
→ Fetch Graph Edges
```

---

## 💎 Critical Decision Points

### Decision 1: Valid Credentials?
```
◇ Valid Credentials?
  ├─[Yes]→ Display Home Screen
  └─[No]→ Display Error → (loop back to Login)
```

### Decision 2: Path Found?
```
◇ Path Found?
  ├─[Yes]→ Check Same Floor?
  └─[No]→ Display Error → (loop back to Trip Planner)
```

### Decision 3: Same Floor?
```
◇ Same Floor?
  ├─[Yes]→ Generate Instructions
  └─[No]→ Handle Multi-Floor Transitions → Generate Instructions
```

---

## 🔀 Parallel Activities (Fork/Join)

Before "Execute A* Pathfinding", add:

```
━━━ Fork ━━━
    ├→ Fetch Building Data
    ├→ Fetch Floor Nodes
    └→ Fetch Graph Edges
━━━ Join ━━━
```

---

## 🎨 Formatting Tips

### Colors
- User: `#E3F2FD` (Light Blue)
- UI Layer: `#E8F5E9` (Light Green)
- Business Logic: `#FFF9C4` (Light Yellow)
- Firebase: `#FFE0B2` (Light Orange)

### Alignment
1. Select multiple nodes
2. Format → Align → Align Center
3. Format → Align → Distribute Vertically

### Auto-Layout
- Format → Layout → Auto Layout (Hierarchical)

---

## ✅ Pre-Export Checklist

- [ ] All 4 swimlanes labeled
- [ ] Initial node (●) at top
- [ ] Final node (◉) at bottom
- [ ] 3 decision nodes with guards ([Yes]/[No])
- [ ] Fork/Join pair for parallel fetching
- [ ] Error handling loops included
- [ ] Multi-floor logic visible
- [ ] All nodes connected with arrows
- [ ] No orphaned elements

---

## 📦 What You'll Create

**Files to save:**
1. `UserNavigationActivityDiagram.mdj` (StarUML project)
2. `ActivityDiagram.png` (exported image)

**Where to save:**
- `/Users/keshavs/Desktop/Indoor_Navigation_System_Main/docs/diagrams/`

---

## 📚 Full Documentation

For detailed instructions, see:
- `STARUML_ACTIVITY_DIAGRAM_GUIDE.md` (Step-by-step tutorial)
- `ACTIVITY_DIAGRAM_SPECIFICATION.md` (Complete workflow spec)
- `activity_diagram_reference.png` (Visual example)

---

## 🆘 Common Issues

**Problem**: Can't find Partition tool  
**Solution**: Look for vertical bars icon in toolbar, or use Model → Add → Partition

**Problem**: Decision node only has one exit  
**Solution**: Right-click decision → Add → Control Flow (add multiple)

**Problem**: Arrows crossing everywhere  
**Solution**: Rearrange nodes, use Format → Layout → Auto Layout

**Problem**: Can't export high-res  
**Solution**: File → Export Diagram → Set DPI to 300

---

## 🎓 Remember

- **Actions** = Rounded rectangles (verbs: "Execute", "Display")
- **Decisions** = Diamonds (questions: "Valid?", "Found?")
- **Guards** = Labels on arrows from decisions ([Yes], [No])
- **Swimlanes** = Vertical columns for different actors/systems

---

**You've got this! 🚀 Follow the guide and you'll have a professional Activity Diagram in no time!**

---

## 📞 Need More Help?

Check the visual reference diagram generated for you:
- See `activity_diagram_reference.png` for a complete example
- Follow the exact structure shown
- Match the swimlane colors and layout

**Estimated Time**: 30-45 minutes for first-time users
