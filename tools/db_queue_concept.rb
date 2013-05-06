
stmt_queue = Array.new

def add_stmt(str)
  stmt_queue.push(str)
end

stmt = db.prepare(stmt_queue.shift)
stmt.execute