--game area dimensions
cw = 32
ch = 18

--size for draw
unit = math.min(1024 / cw, 600 / ch)

love.window.setTitle("snake")

drawgrid = false
status = "running"

mid_x, mid_y = gfx.getDimensions()
font = gfx.newFont(20)

function love.draw()
  runningDraw()
end

direction = {
  up = function()
    snake[1].y = snake[1].y - 1
  end,
  down = function()
    snake[1].y = snake[1].y + 1
  end,
  left = function()
    snake[1].x = snake[1].x - 1
  end,
  right = function()
    snake[1].x = snake[1].x + 1
  end
}

function runningDraw()
  if drawgrid then
    gfx.setColor(0.2, 0.2, 0.2)
    gfx.setLineWidth(.1)
    for x = 1, cw * unit, unit do
      gfx.line(x, 0, x, ch * unit)
    end
    for y = 1, ch * unit, unit do
      gfx.line(0, y, cw * unit, y)
    end
  end
  -- draw the snake rounded rectangle
  for i, snake_part in ipairs(snake) do
    if i == 1 then
      gfx.setColor(0, .4, 0, 1)
    else
      gfx.setColor(0, 0.8, 0)
    end
    gfx.rectangle("fill",
      snake_part.x * unit, snake_part.y * unit,
      unit, unit,
      5, 5);
  end

  if apple then
    gfx.setColor(0.8, 0, 0)
    gfx.rectangle("fill",
      apple.x * unit,
      apple.y * unit,
      unit, unit, 5, 5)
  end

  if status == "completed" then
    gfx.setColor(1, 1, 1)
    gfx.setFont(font)
    gfx.printf("YOU WIN\nPress SPACE to restart", mid_x / 2 - 150, mid_y / 2, 300, "center")
  elseif status == "gameover" then
    gfx.setColor(1, 1, 1)
    gfx.setFont(font)
    gfx.printf("GAME OVER\nPress SPACE to restart", mid_x / 2 - 150, mid_y / 2, 300, "center")
  end
end

function love.update(dt)
  if status == "running" then
    --time limit for speed of snake
    timer = timer + dt
    if timer < speed then
      return
    end

    if #move_queue > 0 then
      move = table.remove(move_queue, 1)
    end

    local last_head_position = { x = snake[1].x, y = snake[1].y }
    local last_tail_position = { x = snake[#snake].x, y = snake[#snake].y }
    move()

    --check food
    local ate = apple ~= nil
        and snake[1].x == apple.x
        and snake[1].y == apple.y

    --set snake snake parts
    --from snake end to second
    for snake_pos = #snake, 3, -1 do
      snake[snake_pos] = snake[snake_pos - 1]
    end

    if #snake > 1 then
      snake[2] = last_head_position
    end

    if ate then
      table.insert(snake, {
        x = last_tail_position.x,
        y = last_tail_position.y
      })
    end

    --check if game is over
    --because snake's head is out of the screen
    if snake[1].x < 0
        or snake[1].y < 0
        or snake[1].x > cw - 1
        or snake[1].y > ch - 1 then
      --game is over
      status = "gameover"
    end

    if ate and #snake >= cw * ch then
      status = "completed"
      apple = nil
      timer = 0
      return
    end

    if ate then
      apple = get_free_position()
    end

    --because snake's head is in the snake
    for _, snake_part in pairs(snake) do
      if _ > 1 then
        if snake[1].x == snake_part.x
            and snake[1].y == snake_part.y
        then
          --game is over
          status = "gameover"
        end
      end
    end
    timer = 0
  end
end

-- function gameoverUpdate(dt)
-- end

move_queue = {}

function queue_move(new_move)
  local previous_move = move_queue[#move_queue] or move
  if new_move == previous_move then
    return
  end
  if (new_move == direction.up and previous_move == direction.down)
      or (new_move == direction.down and previous_move == direction.up)
      or (new_move == direction.left and previous_move == direction.right)
      or (new_move == direction.right and previous_move == direction.left) then
    return
  end
  table.insert(move_queue, new_move)
end

left = function()
  queue_move(direction.left)
end

right = function()
  queue_move(direction.right)
end

up = function()
  queue_move(direction.up)
end

down = function()
  queue_move(direction.down)
end

heading = {
  up = up,
  left = left,
  down = down,
  right = right,
  w = up,
  a = left,
  s = down,
  d = right,

  escape = function()
    love.event.quit()
  end
}

function runningKeypressed(key, _, isrepeat)
  if key == "g" and not isrepeat then
    drawgrid = not drawgrid
  end
  if key ~= "g" and heading[key] then
    heading[key]()
  end
end

function gameoverKeypressed(key, _, isrepeat)
  if key == "space" and not isrepeat then
    start()
  end
  if key == "escape" then
    love.event.quit()
  end
end

function love.keypressed(key, scancode, isrepeat)
  if status == "gameover" or status == "completed" then
    gameoverKeypressed(key, scancode, isrepeat)
  else
    runningKeypressed(key, scancode, isrepeat)
  end
end

function start()
  status = "running"
  move = direction.right
  move_queue = {}
  -- position for snake's head in center
  local start_x = cw / 2
  local start_y = ch / 2
  -- table for the snake
  snake = {
    {
      x = start_x,
      y = start_y
    },
    {
      x = start_x - 1,
      y = start_y
    },
    {
      x = start_x - 2,
      y = start_y
    },
  }
  --set speed and timer
  speed = 0.25
  timer = 0
  --table for the apple
  apple = get_free_position()
end

function get_free_position()
  --random number total game area minus the snake
  randompos = math.random(cw * ch - (#snake))
  local cnt = 0
  --iterate in game area
  gamearea = {}
  for i = 0, cw - 1 do
    for j = 0, ch - 1 do
      --the snake
      gamearea[j * cw + i] = true
    end
  end
  --when snake set to false
  for _, v in ipairs(snake) do
    gamearea[v.y * cw + v.x] = false
  end
  --iterate again and return
  for i = 0, cw - 1 do
    for j = 0, ch - 1 do
      if gamearea[j * cw + i] then
        cnt = cnt + 1
        if cnt == randompos then
          return { x = i, y = j }
        end
      end
    end
  end
end

start()
