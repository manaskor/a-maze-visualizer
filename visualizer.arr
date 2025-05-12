#|
   ====================================================================================
   Welcome to the (A)MAZE VISUALIZER!

   This program allows the user to either randomly generate a maze through two methods
   or edit it however way you'd like, and visualize two types of traversals on it.

   The user also has the ability to "step" back and forth through the 
   different stages of both the traversals & generations and even 
   undo any edits they make. 

   The animation speed of the visualizer is selectable on a scale from 0 to 9, 
   with 0 being the setting to pause the visualizer.

   To edit the maze yourself, you need to click on a square while in edit mode, 
   and you can change which edit mode you're in, as shown below. After
   editing the maze, you can still run either maze generation option
   and it will make these new edits to the maze you just made. 

   You only need to reset the maze when you want to completely clear the board, 
   since everything works dynamically without the need to ever reset. Even
   while the random maze-generation is running, you can interrupt it
   with a traversal or stepping backwards. You can also change the animation speed
   during the traversal or generation.

   When you run either traversal, the numbers on the squares represent 
   how "far" the square was from the source in that particular traversal. 
   The source is the highlighted square, and this can be changed. These
   numbers automatically reset when you run another traversal.

   Some cool algorithmic aspects of the visualizer include depth-first &
   breadth-first traversals and Disjoint-Set Union, Union Find, 
   Kruskal's Random Minimum Spanning Tree for Perfect Maze Generation, 
   & random wall pruning for Arbitrary Maze Generation.

   Have fun!! :)

   ====================================================================================
   Controls:

   Backspace   : Reset maze
   -           : Increase size of maze
   =           : Decrease size of maze
   s           : Change edit mode to Select Source
   l           : Change edit mode to Remove Left Wall
   u           : Change edit mode to Remove Up Wall
   r           : Change edit mode to Remove Right Wall
   d           : Change edit mode to Remove Down Wall
   Left Arrow  : Undo/go one step backward
   Right Arrow : Go one step forward
   ,           : Randomly remove some walls in the maze using Random Walk
   .           : Remove minimum walls to fully connect the maze using Kruskal's
   [           : Depth-first-traversal of maze
   ]           : Breadth-first-traversal of maze
   0-9         : Change animation speed

   ====================================================================================
|#


import image as I
import reactors as R
import sets as S


WIDTH = 800
HEIGHT = 600
BLANK-BG = I.empty-scene(WIDTH, HEIGHT)
SHIFT-BORDER = 2
SHIFT-RIGHT = 5
SHIFT-DOWN = 5
CONFIG-HEIGHT = 34
SCALE-FACTOR = 500
WALL-COLOR = "royal-blue"

MIN-KEY = 0
MAX-KEY = 9

INITIAL-SIZE = 5

SPARSE-FACTOR = 0.3

data MazeSquare:
  | empty-cell
  | source-cell
  | used-cell
  | seen-cell
sharing:
  method make-square(self, cell-dim :: Number) -> Image:
    doc: "produces the square of appropriate color of dimension cell-dim"
    color = cases(MazeSquare) self:
      | empty-cell => "white"
      | source-cell => "light-goldenrod-yellow"
      | used-cell => "light-green"
      | seen-cell => "light-coral"
    end
    I.square(cell-dim, "solid", color)
  end
end

data Edge:
  | edge(id :: Number, dir :: Direction)
end

data Edit:
  | source-edit
  | inc-size
  | dec-size
  | direction-edit(dir :: Direction)
sharing:
  method get-name(self) -> String:
    doc: "produces the appropriate display text"
    cases(Edit) self:
      | source-edit => "Select Source"
      | inc-size => "Increase Size"
      | dec-size => "Decrease Size"
      | direction-edit(dir) => dir.get-name()
    end
  end
end

data Direction:
  | left
  | up
  | right
  | down
sharing:
  method get-index(self) -> Number:
    doc: "produces the appropriate index in a list of four directions"
    cases(Direction) self:
      | left => 0
      | up => 1
      | right => 2
      | down => 3
    end
  end,

  method get-inv(self) -> Direction:
    doc: "produces the appropriate opposite direction"
    cases(Direction) self:
      | left => right
      | up => down
      | right => left
      | down => up
    end
  end,

  method get-name(self) -> String:
    doc: "produces the appropriate display text"
    cases(Direction) self:
      | left => "Remove Left Wall"
      | up => "Remove Up Wall"
      | right => "Remove Right Wall"
      | down => "Remove Down Wall"
    end
  end
end

data Cell:
    cell(id :: Number, group :: Number, value :: Number, total-value :: Number,
      base-img :: Image, is-source :: Boolean, 
      next-left :: Option<Number>, next-up :: Option<Number>, 
      next-right :: Option<Number>, next-down :: Option<Number>) with:
    method open-dir(self, all-cells :: List<Cell>, dir :: Direction) 
      -> List<Cell>:
      doc: "removes the wall in direction dir from cur-cell and its neighbor in all-cells"
      cases(Option) self.valid-neighbors(get-maze-dim(all-cells)).get(dir.get-index()):
        | none => all-cells
        | some(next-id) =>
          cur-cell = self
          next-cell = all-cells.get(next-id)
          parent-1 = all-cells.get(cur-cell.get-group(all-cells))
          parent-2 = all-cells.get(next-cell.get-group(all-cells))
          new-group = num-min(parent-1.id, parent-2.id)
          parent-1-edited = all-cells.set(parent-1.id, 
            parent-1.edit-group(new-group, all-cells))
          parent-2-edited = parent-1-edited.set(parent-2.id,
            parent-2.edit-group(new-group, all-cells))
          opened-cur = parent-2-edited.set(cur-cell.id, 
            cur-cell.set-neighbors(cur-cell.cur-neighbors().set(dir.get-index(), 
                some(next-id))).edit-group(new-group, all-cells))
          opened-cur.set(next-cell.id, 
            next-cell.set-neighbors(next-cell.cur-neighbors().set(dir.get-inv().get-index(),
                some(cur-cell.id))).edit-group(new-group, all-cells))
      end
    end,

    method change-base(self, new-base-img :: Image) -> Cell:
      doc: "changes self.base-img to new-base-img"
      cell(self.id, self.group, self.value, self.total-value, new-base-img, 
        self.is-source, self.next-left, self.next-up, self.next-right, self.next-down)
    end,

    method change-total-value(self, new-total-value :: Number) -> Cell:
      doc: "changes self.total-value to new-total-value"
      cell(self.id, self.group, 
        self.value, new-total-value, 
        self.base-img, 
        self.is-source, self.next-left, self.next-up, self.next-right, self.next-down)
    end,

    method setting-source(self, is-new-source :: Boolean, maze-dim :: Number) -> Cell:
      doc: ```changes self.is-source to is-new-source 
           and changes the appropriate base image```
      cell(self.id, self.group, 
        self.value, self.total-value, 
        (if is-new-source: source-cell.make-square(get-cell-dim(maze-dim)) 
          else: empty-cell.make-square(get-cell-dim(maze-dim)) end), 
        is-new-source, self.next-left, self.next-up, self.next-right, self.next-down)
    end,

    method set-neighbors(self, neighbors :: List<Option<Number>>) -> Cell:
      doc: "changes each neighbor of self to the appropriate index option in neighbors"
      cell(self.id, self.group, self.value, self.total-value, 
        self.base-img, self.is-source,
        neighbors.get(left.get-index()), neighbors.get(up.get-index()),
        neighbors.get(right.get-index()), neighbors.get(down.get-index()))
    end,

    method edit-group(self, new-group :: Number, all-cells :: List<Cell>) -> Cell:
      doc: "changes self.group to the group of new-group using union find in all-cells"
      cell(self.id, all-cells.get(new-group).get-group(all-cells), 
        self.value, self.total-value, self.base-img, self.is-source,
        self.next-left, self.next-up, self.next-right, self.next-down)
    end,

    method cur-neighbors(self) -> List<Option<Number>>:
      doc: "produces a list of neighbors, in the appropriate order"
      [list: self.next-left, self.next-up, self.next-right, self.next-down]
    end,

    method get-group(self, all-cells) -> Number:
      doc: "determines the group of self using union find in all-cells"
      if self.id == self.group:
        self.id
      else:
        all-cells.get(self.group).get-group(all-cells)
      end
    end,

    method valid-neighbors(self, maze-dim :: Number) -> List<Option<Number>>:
      doc: "produces a list of possible neighbors, in the approriate order"
      n = self.id
      x = get-x-normalized(n, maze-dim)
      y = get-y-normalized(n, maze-dim)
      left-neighbor = (if x == 0: none 
        else: some(n - 1) end)
      up-neighbor = (if y == 0: none 
        else: some(n - maze-dim) end)
      right-neighbor = (if x == (maze-dim - 1): none 
        else: some(n + 1) end)
      down-neighbor = (if y == (maze-dim - 1): none 
        else: some(n + maze-dim) end)
      [list: left-neighbor, up-neighbor, right-neighbor, down-neighbor]
    end,

    method draw-cell(self, all-cells) -> Image:
      doc: "adds the appropriate walls to self.base-img, depending on its neighbors"
      cell-dim = get-cell-dim(get-maze-dim(all-cells))
      base-with-value = draw-value(self.base-img, self.total-value - 1, 
        cell-dim)
      fun draw-left(img :: Image) -> Image:
        doc: "draws a left wall onto img"
        I.add-line(img, (-1 * (cell-dim / 2)) + SHIFT-BORDER, cell-dim, 
          (-1 * (cell-dim / 2)) + SHIFT-BORDER, 0, WALL-COLOR)
      end

      fun draw-right(img :: Image) -> Image:
        doc: "draws a right wall onto img"
        I.add-line(img, (cell-dim / 2) - SHIFT-BORDER, cell-dim, 
          (cell-dim / 2) - SHIFT-BORDER, 0, WALL-COLOR)
      end

      fun draw-up(img :: Image) -> Image:
        doc: "draws an up wall onto img"
        I.add-line(img, 0, (-1 * (cell-dim / 2)) + SHIFT-BORDER, 
          cell-dim, (-1 * (cell-dim / 2)) + SHIFT-BORDER, WALL-COLOR)
      end

      fun draw-down(img :: Image) -> Image:
        doc: "draws a down wall onto img"
        I.add-line(img, cell-dim, (cell-dim / 2) - SHIFT-BORDER, 
          0, (cell-dim / 2) - SHIFT-BORDER, WALL-COLOR)
      end
      all-line-functions = [list: draw-left, draw-up, draw-right, draw-down]
      my-neighbors = self.cur-neighbors()
      transformed-line-functions =
        map2(lam(cur-neighbor, cur-func):
            cases(Option) cur-neighbor:
              | none => 
                cur-func
              | some(a) =>
                {(img :: Image): img}
            end
          end, my-neighbors, all-line-functions)
      fold(lam(prev-img, cur-func):
          prev-img ^ cur-func
        end, 
        base-with-value, 
        transformed-line-functions)
    end
end

data WorldState:
    ws(all-cells :: List<Cell>, to-update :: List<(-> List<Cell>)>, 
      update-index :: Number, edit-type :: Edit,
      locked-out :: Boolean, 
      time :: Number, inv-tick-rate :: Number,
      prev-state :: (-> Option<WorldState>)) with:
    method display-config(self) -> Image:
      doc: "produces the config display"
      text(self.edit-text() + self.speed-text(), 30, WALL-COLOR)
    end,

    method edit-text(self) -> String:
      doc: "produces the display text for the edit mode"
      if self.locked-out: " Still Running..." 
      else: " Edit Mode: " + self.edit-type.get-name() end
    end,

    method speed-text(self) -> String:
      doc: "produces the display text for the animation speed of w"
      " | Animation Speed: " + num-to-string(speed-to-time-per-tick(self.inv-tick-rate))
    end
end

fun valid-speed(speed :: Number) -> Boolean:
  doc: "determines if speed is a valid animation-speed"
  num-is-integer(speed) and (MIN-KEY <= speed) and (speed <= MAX-KEY)
where:
  0 satisfies valid-speed
  1 satisfies valid-speed
  -1 violates valid-speed
  9 satisfies valid-speed
  10 violates valid-speed
end

fun speed-to-time-per-tick(speed :: Number%(valid-speed)) -> Number:
  doc: ```converts speed to the number of ticks before the screen updates;
       produces 0 if speed is set to 0```
  ask:
    | speed == 0 then: 0
    | otherwise: (MAX-KEY - speed) + (MIN-KEY + 1)
  end
where:
  speed-to-time-per-tick(0) is 0
  speed-to-time-per-tick(1) is 9
  speed-to-time-per-tick(4) is 6
  speed-to-time-per-tick(6) is 4
  speed-to-time-per-tick(9) is 1
end

fun get-maze-dim(all-cells :: List<Cell>) -> Number:
  doc: "produces the dimension of the maze from all-cells"
  num-sqrt(all-cells.length())
where:
  get-maze-dim(initialize-state(5).all-cells) is 5
  get-maze-dim(initialize-state(10).all-cells) is 10
  get-maze-dim(initialize-state(1).all-cells) is 1
end

fun get-cell-dim(maze-dim :: Number) -> Number:
  doc: "produces the size of the cell from the maze dimension maze-dim"
  SCALE-FACTOR / maze-dim
where:
  get-cell-dim(1) is SCALE-FACTOR
  get-cell-dim(2) is SCALE-FACTOR / 2
  get-cell-dim(20) is SCALE-FACTOR / 20
end

fun draw-value(img :: Image, value :: Number, cell-dim :: Number):
  doc: "draws value onto img, scaled based on cell-dim"
  MAX-FONT = 255
  FONT-SCALE = 0.3
  FONT-SIZE = num-min(MAX-FONT, FONT-SCALE * cell-dim)
  I.overlay(text-font(num-to-string(value), FONT-SIZE, 
      WALL-COLOR, "Treasure Map Deadhand",
      "decorative", "normal", "normal", false), img)
where:
  MAX-FONT = 255
  FONT-SCALE = 0.3
  CELL-DIM-1 = 5
  CELL-DIM-2 = 1
  FONT-SIZE = num-min(MAX-FONT, FONT-SCALE * CELL-DIM-1)
  draw-value(empty-cell.make-square(CELL-DIM-1), 1, CELL-DIM-1)
    is I.overlay(text-font(num-to-string(CELL-DIM-1), FONT-SIZE, 
      WALL-COLOR, "Treasure Map Deadhand",
      "decorative", "normal", "normal", false), empty-cell.make-square(CELL-DIM-1))
  draw-value(empty-cell.make-square(CELL-DIM-2), 3, CELL-DIM-1) 
    is I.overlay(text-font(num-to-string(CELL-DIM-2), FONT-SIZE, 
      WALL-COLOR, "Treasure Map Deadhand",
      "decorative", "normal", "normal", false), empty-cell.make-square(CELL-DIM-2))
end

fun find-source(all-cells :: List<Cell>) -> Cell:
  doc: ```identifies the source in all-cells; expects all-cells to contain exactly
       one source```
  cases(List) filter(lam(cur-cell): cur-cell.is-source end, all-cells):
    | empty => all-cells.get(0)
    | link(f, r) => f
  end
where:
  find-source(initialize-state(1).all-cells)
    is initialize-state(1).all-cells.get(0)
  find-source(initialize-state(5).all-cells)
    is initialize-state(5).all-cells.get(0)
  find-source(shuffle(initialize-state(9).all-cells))
    is initialize-state(9).all-cells.get(0)
end

fun set-source(all-cells :: List<Cell>, cur-id :: Number)
  -> List<Cell>:
  doc: "produces a new list from all-cells where the only source is at index cur-id"
  map(lam(cur-cell): 
      cur-cell.setting-source(cur-cell.id == cur-id, get-maze-dim(all-cells))
    end, all-cells)
where:
  find-source(set-source(initialize-state(5).all-cells, 7)).id
    is 7
  find-source(set-source(initialize-state(9).all-cells, 0)).id
    is 0
  find-source(set-source(initialize-state(3).all-cells, 8)).id
    is 8
end

fun get-x-normalized(x :: Number, maze-dim :: Number) -> Number:
  doc: "produces the zero-based column number in the maze, from the x-coordinate x"
  num-modulo(x, maze-dim)
where:
  get-x-normalized(0, 1) is 0
  get-x-normalized(9, 5) is 4
  get-x-normalized(9, 3) is 0
end

fun get-y-normalized(y :: Number, maze-dim :: Number) -> Number:
  doc: "produces the zero-based row number in the maze, frmo the y-coordinate y"
  num-truncate(y / maze-dim)
where:
  get-y-normalized(0, 1) is 0
  get-y-normalized(9, 5) is 1
  get-y-normalized(9, 3) is 3
end

fun update-cells(all-cells :: List<Cell>, cur-updating :: List<Cell>)
  -> List<Cell>:
  doc: "updates only the cells in all-cells that correspond to cells in cur-updating"
  fold(
    lam(prev-list, cur-cell): 
      prev-list.set(cur-cell.id, cur-cell)
    end, 
    all-cells, cur-updating)
where:
  template-cell-1 = initialize-state(5).all-cells.get(0)
  template-cell-2 = initialize-state(5).all-cells.get(7)
  update-cells(initialize-state(5).all-cells, empty) is initialize-state(5).all-cells
end

fun when-tick(w :: WorldState) -> WorldState:
  doc: "produces the WorldState in the subsequent tick"
  if (w.update-index >= w.to-update.length()):
    ws(w.all-cells, w.to-update, w.update-index, w.edit-type, 
      false, w.time + 1, w.inv-tick-rate, w.prev-state)
  else if (w.inv-tick-rate == 0)
    or not(num-modulo(w.time, w.inv-tick-rate) == (w.inv-tick-rate - 1)):
    ws(w.all-cells, w.to-update, w.update-index, w.edit-type, 
      w.locked-out, w.time + 1, w.inv-tick-rate, w.prev-state)
  else:
    cur-updating = w.to-update.get(w.update-index)()
    new-cells = update-cells(w.all-cells, cur-updating)
    ws(new-cells, w.to-update, w.update-index + 1, w.edit-type, 
      w.locked-out, w.time + 1, w.inv-tick-rate, {(): some(w)})
  end
end


fun initialize-state(maze-dim :: Number) -> WorldState:
  doc: "produces an initial WorldState corresponding to a maze of dimension maze-dim"
  new-starting-cells = 
    map({(cur-id :: Number): 
        cell(cur-id, cur-id, 1, 1, empty-cell.make-square(get-cell-dim(maze-dim)), 
          false, none, none, none, none)}, 
      range(0, num-sqr(maze-dim)))
  ws(set-source(new-starting-cells, 0), empty, 0, source-edit, 
    false, MIN-KEY, MAX-KEY, {(): none})
end

fun when-key(w :: WorldState, key :: String) -> WorldState:
  doc: "produces the WorldState after a key is pressed, based on the controls"
  cases(Option) string-to-number(key):
    | none => 
      ask:
        | key == "backspace" then: initialize-state(get-maze-dim(w.all-cells))
        | key == "-" then:
          ws(w.all-cells, empty, 0, 
            dec-size, w.locked-out, 
            w.time, 0, w.prev-state)
        | key == "=" then:
          ws(w.all-cells, empty, 0, 
            inc-size, w.locked-out, 
            w.time, 0, w.prev-state)
        | key == "s" then:
          ws(w.all-cells, w.to-update, w.update-index, 
            source-edit, w.locked-out, 
            w.time, 0, w.prev-state)
        | key == "l" then: 
          ws(w.all-cells, w.to-update, w.update-index, 
            direction-edit(left), w.locked-out, 
            w.time, 0, w.prev-state)
        | key == "u" then:
          ws(w.all-cells, w.to-update, w.update-index, 
            direction-edit(up), w.locked-out, 
            w.time, 0, w.prev-state)
        | key == "r" then:
          ws(w.all-cells, w.to-update, w.update-index, 
            direction-edit(right), w.locked-out, 
            w.time, 0, w.prev-state)
        | key == "d" then:
          ws(w.all-cells, w.to-update, w.update-index, 
            direction-edit(down), w.locked-out, 
            w.time, 0, w.prev-state)
        | key == "left" then:
          cases(Option) w.prev-state():
            | none => w
            | some(prev-w) => 
              ws(prev-w.all-cells, prev-w.to-update, prev-w.update-index, 
                w.edit-type, prev-w.locked-out, 
                prev-w.time, 0, prev-w.prev-state)
          end
        | key == "right" then:
          next-w = when-tick(ws(w.all-cells, w.to-update, w.update-index, 
              w.edit-type, w.locked-out, MIN-KEY, MIN-KEY + 1, w.prev-state))
          ws(next-w.all-cells, next-w.to-update, next-w.update-index, 
            w.edit-type, next-w.locked-out, 
            w.time + 1, 0, next-w.prev-state)
        | key == "." then:
          ws(w.all-cells,
            rand-spanning-tree(w.all-cells), 
            0,
            w.edit-type, w.locked-out, 0, MIN-KEY + 1, 
            {(): some(w)})
        | key == "," then:
          ws(w.all-cells,
            rand-maze(w.all-cells), 
            0,
            w.edit-type, w.locked-out, 0, MIN-KEY + 1, 
            {(): some(w)})
        | key == "[" then:
          ws(w.all-cells, maze-traversal(w.all-cells, 
              lam(lst-1, lst-2): lst-1 + lst-2 end,
              get-cell-dim(get-maze-dim(w.all-cells))), 
            0, w.edit-type, w.locked-out,
            0, speed-to-time-per-tick(num-max(MIN-KEY + 1, 
                speed-to-time-per-tick(w.inv-tick-rate))), {(): some(w)})
        | key == "]" then: 
          ws(w.all-cells, maze-traversal(w.all-cells, 
              lam(lst-1, lst-2): lst-2 + lst-1 end,
              get-cell-dim(get-maze-dim(w.all-cells))), 
            0, w.edit-type, w.locked-out,
            0, speed-to-time-per-tick(num-max(MIN-KEY + 1, 
                speed-to-time-per-tick(w.inv-tick-rate))), {(): some(w)})
        | otherwise: w
      end
    | some(num-key) =>
      time-per-tick = speed-to-time-per-tick(num-key)
      new-time = (if time-per-tick == 0: w.time 
        else: w.time - num-modulo(w.time, time-per-tick) end)
      ws(w.all-cells, w.to-update, w.update-index, w.edit-type,
        w.locked-out, new-time, time-per-tick, w.prev-state)
  end
end

fun when-mouse(w :: WorldState, x :: Number, y :: Number, event :: String) 
  -> WorldState:
  doc: "produces the WorldState after a mouse event, according to Edit Controls"
  ask:
    | event == "button-down" then: 
      if w.locked-out:
        w
      else:
        cell-dim = get-cell-dim(get-maze-dim(w.all-cells))
        x-index = num-truncate((x - SHIFT-RIGHT) / (cell-dim))
        y-index = num-truncate((y - SHIFT-DOWN - CONFIG-HEIGHT) / (cell-dim))
        if ((x-index < 0) or (x-index >= get-maze-dim(w.all-cells)) 
            or (y-index < 0) or (y-index >= get-maze-dim(w.all-cells))): w
        else:
          cur-id = (get-maze-dim(w.all-cells) * y-index) + x-index
          cur-cell = w.all-cells.get(cur-id)
          cases(Edit) w.edit-type:
            | direction-edit(dir) => 
              new-cells = cur-cell.open-dir(w.all-cells, dir)
              if w.all-cells == new-cells:
                w
              else:
                ws(new-cells, w.to-update, w.update-index, w.edit-type,
                  w.locked-out, w.time, w.inv-tick-rate, {(): some(w)})
              end
            | source-edit =>
              new-cells = set-source(w.all-cells, cur-id)
              ws(new-cells, w.to-update, w.update-index, w.edit-type,
                w.locked-out, w.time, w.inv-tick-rate, {(): some(w)})
            | inc-size => 
              new-size = get-maze-dim(w.all-cells) + 1
              initialize-state(new-size)
            | dec-size =>
              new-size = num-max(1, get-maze-dim(w.all-cells) - 1)
              next-w = initialize-state(new-size)
              next-w
          end
        end
      end
    | otherwise: w
  end
end

fun display-all-cells(num-left :: Number, background :: Image, all-cells :: List<Cell>) 
  -> Image:
  doc: ```displays squares in all-cells with ids starting from num-left 
       counting back to zero onto background```
  if (num-left == 0) or (all-cells == empty):
    background
  else:
    cell-dim = get-cell-dim(get-maze-dim(all-cells))
    x = (get-x-normalized(num-left - 1, get-maze-dim(all-cells)) * cell-dim) + SHIFT-RIGHT
    y = (get-y-normalized(num-left - 1, get-maze-dim(all-cells)) * cell-dim) + SHIFT-DOWN
    display-all-cells(num-left - 1, 
      I.place-image(all-cells.get(num-left - 1).draw-cell(all-cells), 
        x + (cell-dim / 2), y + (cell-dim / 2), background), 
      all-cells)
  end
end

fun generate-edges(all-cells :: List<Cell>, original-size :: Number) -> List<Edge>:
  doc: ```produces a list of all possible edges in all-cells that is taken
       from a maze of dimension original-size```
  cases(List) all-cells:
    | empty => empty
    | link(cur-cell, r) =>
      neighbors = cur-cell.valid-neighbors(original-size)
      edges = fold2(
        lam(prev-list, cur-dir, cur-opt):
          cases(Option) cur-opt:
            | none => prev-list
            | some(cur-neighbor) =>
              link(edge(cur-cell.id, cur-dir), prev-list)
          end
        end, empty, [list: left, up, right, down], neighbors)
      edges + generate-edges(r, original-size)
  end
end

fun maze-traversal(original-all-cells :: List<Cell>, 
    joiner :: (List<Cell>, List<Cell> -> List<Cell>),
    cell-dim :: Number)
  -> List<(-> List<Cell>)>:
  doc: ```produces a series of traversal updates to be applied to original-all-cells,
       the traversal of which depends on how joiner combines two lists```
  fun maze-traversal-helper(
      todo :: List<Number>,
      seen :: List<Number>,
      output :: List<(-> List<Cell>)>,
      all-cells :: List<Cell>)
    -> List<(-> List<Cell>)>:
    doc: ```traverses the maze starting from values in todo;
         adapted from function shown in class;
         Inspiration Credit: Shriram Krishnamurthi```
    cases(List) todo:
      | empty => 
        output
      | link(next, r-todo) =>
        if member(seen, next):
          maze-traversal-helper(r-todo, seen, output, all-cells)
        else:
          neighbors-options = 
            filter(lam(cur-opt): 
                cases(Option) cur-opt:
                  | none => false
                  | some(_) => true
                end
              end, all-cells.get(next).cur-neighbors())
          real-neighbors = map(lam(cur-opt): cur-opt.value end, neighbors-options)
          not-seen-neighbors = filter(lam(cur-neighbor): 
            not(member(seen, cur-neighbor)) end, real-neighbors)
          cur-updating = map(lam(cur-id): 
              cur-cell = all-cells.get(cur-id)
              (if cur-cell.is-source: 
                  cur-cell
                else: 
                  changed-image = cur-cell.change-base(used-cell.make-square(cell-dim))
                  new-total-value = all-cells.get(next).total-value + cur-cell.value
                changed-image.change-total-value(new-total-value) end)
            end, not-seen-neighbors)
          new-output = output + [list: {(): cur-updating}]
          new-cells = update-cells(all-cells, cur-updating)
          new-seen = seen + [list: next]
          maze-traversal-helper(joiner(real-neighbors, r-todo), new-seen, new-output,
            new-cells)
        end
    end
  end
  reset-all-cells = map(lam(cur-cell): 
      cur-cell.change-total-value(cur-cell.value).setting-source(cur-cell.is-source, 
      get-maze-dim(original-all-cells)) end, original-all-cells)
  source = find-source(reset-all-cells)
  maze-traversal-helper([list: source.id], empty, 
    [list: {(): reset-all-cells}], reset-all-cells)
end

fun rand-spanning-tree(original-all-cells :: List<Cell>) 
  -> List<(-> List<Cell>)>:
  doc: ```produces a series of removal updates to produce a 
       random minimum spanning maze for original-all-cells```
  fun rand-spanning-tree-helper(all-edges :: List<Edge>, all-cells :: List<Cell>)
    -> List<(-> List<Cell>)>:
    doc: ```produces a series of removal updates to produce a 
       random minimum spanning maze for original-all-cells from all-edges```
    cases(List) all-edges:
      | empty => empty
      | link(cur-edge, r) =>
        len = all-edges.length()
        cur-cell = all-cells.get(cur-edge.id)
        neighbor-id = cur-cell.valid-neighbors(
          get-maze-dim(all-cells)).get(cur-edge.dir.get-index()).value
        group-1 = cur-cell.get-group(all-cells)
        group-2 = all-cells.get(neighbor-id).get-group(all-cells)
        if group-1 == group-2:
          rand-spanning-tree-helper(r, all-cells)
        else:
          new-cells = all-cells.get(cur-edge.id).open-dir(all-cells, cur-edge.dir)
          set-new-cells = S.list-to-list-set(new-cells)
          set-all-cells = S.list-to-list-set(all-cells)
          changed-cells = set-new-cells.difference(set-all-cells).to-list()
          link({(): changed-cells}, rand-spanning-tree-helper(r, new-cells))
        end
    end
  end
  original-all-edges = generate-edges(original-all-cells, 
    get-maze-dim(original-all-cells))
  rand-spanning-tree-helper(shuffle(original-all-edges), original-all-cells)
end

fun rand-maze(original-all-cells :: List<Cell>) 
  -> List<(-> List<Cell>)>:
  doc: "produces a series of removal updates to produce a maze with random deletions"
  fun rand-maze-helper(all-edges :: List<Edge>, all-cells :: List<Cell>) -> List<(-> List<Cell>)>:
    doc: ```produces a series of removal updates to produce a 
       random minimum spanning maze for original-all-cells from all-edges```
    cases(List) all-edges:
      | empty => empty
      | link(cur-edge, r) =>
        len = all-edges.length()
        cur-cell = all-cells.get(cur-edge.id)
        neighbor-id = cur-cell.valid-neighbors(
          get-maze-dim(all-cells)).get(cur-edge.dir.get-index()).value
        new-cells = all-cells.get(cur-edge.id).open-dir(all-cells, cur-edge.dir)
        set-new-cells = S.list-to-list-set(new-cells)
        set-all-cells = S.list-to-list-set(all-cells)
        changed-cells = set-new-cells.difference(set-all-cells).to-list()
        link({(): changed-cells}, rand-maze-helper(r, new-cells))
    end
  end
  original-all-edges = generate-edges(original-all-cells, 
    get-maze-dim(original-all-cells))
  where-to-cut = num-truncate(SPARSE-FACTOR * 
    (num-random(original-all-edges.length() + 1)))
  left-edges = shuffle(original-all-edges).split-at(where-to-cut).prefix
  rand-maze-helper(left-edges, original-all-cells)
end

fun display-world(w :: WorldState) -> Image:
  doc: "displays the maze with the config display of w"
  above(w.display-config(), 
    display-all-cells(w.all-cells.length(), BLANK-BG, w.all-cells))
end

anim = reactor:
  init: initialize-state(INITIAL-SIZE),
  on-tick: when-tick,
  on-key: when-key,
  on-mouse: when-mouse,
  to-draw: display-world
end

R.interact(anim)
