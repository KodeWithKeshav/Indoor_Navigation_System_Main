# StarUML Use Case Diagram Guide - Indoor Navigation System

## 📋 Overview
This guide will help you create a comprehensive **Use Case Diagram** for the Indoor Navigation System using StarUML. The diagram will illustrate the system's functionality from the user's perspective, showing actors and their interactions with the system.

---

## 🎯 What We'll Model

**System Functionality:**
- **Actors**: Admin, Student/User, Guest, System (Firebase)
- **Use Cases**: Login, Manage Maps, Find Path, View Navigation, etc.
- **Relationships**: Associations, Include, Extend, Generalization

---

## 🛠 Prerequisites

1. **StarUML installed** from https://staruml.io/
2. **Understanding of system features**
3. **Basic UML Use Case concepts**

---

## 📐 Step-by-Step Instructions

### Step 1: Create New Use Case Diagram
1. Open **StarUML**
2. In **Model Explorer**, right-click on **Model**
3. Select **Add Diagram → Use Case Diagram**
4. Rename to `IndoorNavigationUseCaseDiagram`

---

### Step 2: Add System Boundary

1. Click **System** tool (rectangle)
2. Draw a large rectangle on canvas
3. Name it `Indoor Navigation System`
4. This represents your system boundary

**All use cases will be placed INSIDE this boundary**

---

### Step 3: Add Actors

Actors are placed OUTSIDE the system boundary.

#### Actor 1: User (General User)
1. Click **Actor** tool (stick figure)
2. Place to the LEFT of system boundary
3. Name it `User`

#### Actor 2: Admin
1. Add another **Actor**
2. Place to the LEFT, below User
3. Name it `Admin`

#### Actor 3: Guest
1. Add **Actor**
2. Place to the LEFT, below Admin
3. Name it `Guest`

#### Actor 4: Firebase (System Actor)
1. Add **Actor**
2. Place to the RIGHT of system boundary
3. Name it `Firebase`
4. Add stereotype `«system»`

---

### Step 4: Add Actor Generalization

Show that Admin and Guest are types of Users:

1. Click **Generalization** tool (hollow arrow)
2. Draw from `Admin` to `User`
3. Draw from `Guest` to `User`

This shows Admin and Guest inherit User capabilities.

---

### Step 5: Add Use Cases (Inside System Boundary)

Use cases are placed INSIDE the system boundary.

#### Authentication Use Cases
1. Click **Use Case** tool (oval)
2. Add these use cases:
   - `Login`
   - `Logout`
   - `Authenticate User`

#### Map Management Use Cases (Admin)
1. Add use cases:
   - `Manage Organizations`
   - `Manage Buildings`
   - `Manage Floors`
   - `Manage Rooms`
   - `Manage Corridors`
   - `View Map Data`

#### Navigation Use Cases (User)
1. Add use cases:
   - `Select Building`
   - `Select Floor`
   - `Choose Start Location`
   - `Choose End Location`
   - `Calculate Path`
   - `View Navigation Instructions`
   - `Follow Directions`
   - `Enable Accessibility Mode`

#### Data Use Cases
1. Add use cases:
   - `Fetch Map Data`
   - `Store Map Data`

---

### Step 6: Add Associations (Actor to Use Case)

Connect actors to their use cases with **Association** (simple line).

#### User Associations
1. Click **Association** tool
2. Connect `User` to:
   - `Login`
   - `Logout`
   - `Select Building`
   - `Select Floor`
   - `Choose Start Location`
   - `Choose End Location`
   - `View Navigation Instructions`
   - `Follow Directions`
   - `Enable Accessibility Mode`

#### Admin Associations
1. Connect `Admin` to:
   - `Manage Organizations`
   - `Manage Buildings`
   - `Manage Floors`
   - `Manage Rooms`
   - `Manage Corridors`
   - `View Map Data`

**Note**: Admin inherits User capabilities via generalization

#### Guest Associations
1. Connect `Guest` to:
   - `Select Building`
   - `Select Floor`
   - `View Navigation Instructions`

**Note**: Guest has limited access (no login required)

#### Firebase Associations
1. Connect `Firebase` to:
   - `Authenticate User`
   - `Fetch Map Data`
   - `Store Map Data`

---

### Step 7: Add Include Relationships

**Include** = Use case ALWAYS includes another use case

#### Include 1: Login includes Authenticate User
1. Click **Include** tool (dashed arrow with «include»)
2. Draw from `Login` to `Authenticate User`
3. Label: `«include»`

**Meaning**: Login always requires authentication

#### Include 2: Calculate Path includes Fetch Map Data
1. Draw **Include** from `Calculate Path` to `Fetch Map Data`

**Meaning**: Path calculation always requires fetching map data

#### Include 3: Manage Buildings includes Fetch Map Data
1. Draw **Include** from `Manage Buildings` to `Fetch Map Data`

#### Include 4: Manage Buildings includes Store Map Data
1. Draw **Include** from `Manage Buildings` to `Store Map Data`

**Repeat for other Manage use cases** (Floors, Rooms, Corridors)

---

### Step 8: Add Extend Relationships

**Extend** = Use case OPTIONALLY extends another use case

#### Extend 1: Enable Accessibility Mode extends Calculate Path
1. Click **Extend** tool (dashed arrow with «extend»)
2. Draw from `Enable Accessibility Mode` to `Calculate Path`
3. Label: `«extend»`

**Meaning**: Accessibility mode is an optional extension of path calculation

---

### Step 9: Organize and Format

#### Layout
1. **Actors on sides**: Users on left, System actors on right
2. **Use cases in center**: Group by functionality
3. **Minimize crossing lines**: Rearrange use cases

#### Grouping (Optional)
Create **packages** or visual groups:
- Authentication (top)
- Map Management (left side)
- Navigation (right side)
- Data Operations (bottom)

#### Color Coding
1. Select **Authentication use cases** → Light Blue
2. Select **Admin use cases** → Light Orange
3. Select **User navigation use cases** → Light Green
4. Select **Data use cases** → Light Yellow

#### Alignment
1. Select use cases → Format → Align → Distribute Vertically
2. Align actors on left side

---

### Step 10: Add Notes

#### Note 1: Admin Privileges
```
Position: Near Admin actor
Text: "Admin has full access to map management
       Inherits all User capabilities"
```

#### Note 2: Guest Access
```
Position: Near Guest actor
Text: "Guest can view navigation without login
       Limited to read-only access"
```

#### Note 3: A* Algorithm
```
Position: Near Calculate Path
Text: "Uses A* pathfinding algorithm
       Supports multi-floor navigation
       Accessibility mode avoids stairs"
```

---

### Step 11: Export Diagram

1. **File → Export Diagram → PNG**
2. Resolution: **300 DPI**
3. Save as `UseCaseDiagram.png` in `/docs/diagrams/`

---

## 🎨 Diagram Best Practices

### Visual Clarity
- **Actors outside boundary**: Always place actors outside system box
- **Use cases inside boundary**: All use cases inside system box
- **Group related use cases**: Keep similar functionality together
- **Minimize line crossings**: Rearrange elements for clarity

### Naming Conventions
- **Actors**: Nouns (User, Admin, Firebase)
- **Use cases**: Verb phrases (Login, Calculate Path, Manage Buildings)
- **Keep names short**: 2-4 words maximum

### Relationship Guidelines
- **Association**: Simple line (Actor to Use Case)
- **Include**: Dashed arrow with «include» (mandatory inclusion)
- **Extend**: Dashed arrow with «extend» (optional extension)
- **Generalization**: Solid arrow with hollow head (inheritance)

---

## 📊 Key Elements Reference

| Element | StarUML Tool | Purpose | Example |
|---------|-------------|---------|---------|
| **Actor** | Actor | User or system | User, Admin, Firebase |
| **Use Case** | Use Case | System functionality | Login, Calculate Path |
| **System** | System | System boundary | Indoor Navigation System |
| **Association** | Association | Actor uses use case | User → Login |
| **Include** | Include | Mandatory inclusion | Login «include» Authenticate |
| **Extend** | Extend | Optional extension | Accessibility «extend» Calculate |
| **Generalization** | Generalization | Actor inheritance | Admin → User |

---

## 🔍 Use Case List

### Authentication
- Login
- Logout
- Authenticate User

### Map Management (Admin Only)
- Manage Organizations
- Manage Buildings
- Manage Floors
- Manage Rooms
- Manage Corridors
- View Map Data

### Navigation (User/Guest)
- Select Building
- Select Floor
- Choose Start Location
- Choose End Location
- Calculate Path
- View Navigation Instructions
- Follow Directions
- Enable Accessibility Mode

### Data Operations
- Fetch Map Data
- Store Map Data

---

## ✅ Final Checklist

- [ ] System boundary box is drawn
- [ ] All actors are placed OUTSIDE boundary
- [ ] All use cases are placed INSIDE boundary
- [ ] User, Admin, Guest actors are added
- [ ] Firebase system actor is added
- [ ] Actor generalizations are shown (Admin → User, Guest → User)
- [ ] All associations are drawn (Actor to Use Case)
- [ ] Include relationships are added (Login → Authenticate)
- [ ] Extend relationships are added (Accessibility → Calculate Path)
- [ ] Use cases are grouped logically
- [ ] Color coding is applied
- [ ] Notes explain key concepts
- [ ] Diagram is exported as PNG

---

## 💡 Quick Tips

1. **Start with actors**: Identify who uses the system
2. **List use cases**: What can each actor do?
3. **Draw associations**: Connect actors to their use cases
4. **Add includes**: What's always required?
5. **Add extends**: What's optional?
6. **Organize visually**: Group related functionality

---

## 🎓 Learning Resources

- **StarUML Use Case**: https://docs.staruml.io/working-with-diagrams/use-case-diagram
- **UML Use Cases**: https://www.uml-diagrams.org/use-case-diagrams.html

---

**Your Use Case Diagram will clearly show WHO uses WHAT in your system! 🎯**
