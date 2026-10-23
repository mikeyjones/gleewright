//// ARIA roles, used to locate elements with `page.get_by_role`.

/// An ARIA role.
pub type Role {
  Alert
  AlertDialog
  Application
  Article
  Banner
  Blockquote
  Button
  Caption
  Cell
  Checkbox
  Code
  ColumnHeader
  ComboBox
  Complementary
  ContentInfo
  Definition
  Deletion
  Dialog
  Directory
  Document
  Emphasis
  Feed
  Figure
  Form
  Generic
  Grid
  GridCell
  Group
  Heading
  Img
  Insertion
  Link
  List
  ListBox
  ListItem
  Log
  Main
  Marquee
  Math
  Meter
  Menu
  MenuBar
  MenuItem
  MenuItemCheckbox
  MenuItemRadio
  Navigation
  None
  Note
  Option
  Paragraph
  Presentation
  ProgressBar
  Radio
  RadioGroup
  Region
  Row
  RowGroup
  RowHeader
  ScrollBar
  Search
  SearchBox
  Separator
  Slider
  SpinButton
  Status
  Strong
  Subscript
  Superscript
  Switch
  Tab
  Table
  TabList
  TabPanel
  Term
  TextBox
  Time
  Timer
  Toolbar
  Tooltip
  Tree
  TreeGrid
  TreeItem
}

/// The ARIA name of a role, e.g. `"button"` for `Button`.
pub fn to_string(role: Role) -> String {
  case role {
    Alert -> "alert"
    AlertDialog -> "alertdialog"
    Application -> "application"
    Article -> "article"
    Banner -> "banner"
    Blockquote -> "blockquote"
    Button -> "button"
    Caption -> "caption"
    Cell -> "cell"
    Checkbox -> "checkbox"
    Code -> "code"
    ColumnHeader -> "columnheader"
    ComboBox -> "combobox"
    Complementary -> "complementary"
    ContentInfo -> "contentinfo"
    Definition -> "definition"
    Deletion -> "deletion"
    Dialog -> "dialog"
    Directory -> "directory"
    Document -> "document"
    Emphasis -> "emphasis"
    Feed -> "feed"
    Figure -> "figure"
    Form -> "form"
    Generic -> "generic"
    Grid -> "grid"
    GridCell -> "gridcell"
    Group -> "group"
    Heading -> "heading"
    Img -> "img"
    Insertion -> "insertion"
    Link -> "link"
    List -> "list"
    ListBox -> "listbox"
    ListItem -> "listitem"
    Log -> "log"
    Main -> "main"
    Marquee -> "marquee"
    Math -> "math"
    Meter -> "meter"
    Menu -> "menu"
    MenuBar -> "menubar"
    MenuItem -> "menuitem"
    MenuItemCheckbox -> "menuitemcheckbox"
    MenuItemRadio -> "menuitemradio"
    Navigation -> "navigation"
    None -> "none"
    Note -> "note"
    Option -> "option"
    Paragraph -> "paragraph"
    Presentation -> "presentation"
    ProgressBar -> "progressbar"
    Radio -> "radio"
    RadioGroup -> "radiogroup"
    Region -> "region"
    Row -> "row"
    RowGroup -> "rowgroup"
    RowHeader -> "rowheader"
    ScrollBar -> "scrollbar"
    Search -> "search"
    SearchBox -> "searchbox"
    Separator -> "separator"
    Slider -> "slider"
    SpinButton -> "spinbutton"
    Status -> "status"
    Strong -> "strong"
    Subscript -> "subscript"
    Superscript -> "superscript"
    Switch -> "switch"
    Tab -> "tab"
    Table -> "table"
    TabList -> "tablist"
    TabPanel -> "tabpanel"
    Term -> "term"
    TextBox -> "textbox"
    Time -> "time"
    Timer -> "timer"
    Toolbar -> "toolbar"
    Tooltip -> "tooltip"
    Tree -> "tree"
    TreeGrid -> "treegrid"
    TreeItem -> "treeitem"
  }
}
