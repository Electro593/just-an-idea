# Logic

To retrieve:

1. Find the file
2. Find the innermost valid range
3. Find the link

## How this is updated?

- We can only do all or nothing to query the new AST

### Option 1: Scoped Invalidation

We can know the range of the file which was modified, and bump stored line numbers, only invalidating the range which was changed. It would require invalidating anything that referred to what was changed too.

- **Pros:**
  - Avoids write-locking the whole thing
  - DB-structure allows for easier lookup

### Option 2: Replace the database every time

We can just replace the whole thing every time.

- **Pros:**
  - Straightforward
- **Cons:**
  - Incurs much more write I/O

## Steps

1. Server creates a new database if it doesn't exist
2. Server receives events:

   - Change document:
      1. Invalidate region
      2. Mark dirty

   - Save document:
      1. If dirty: spawn compiler (lenient)

   - Rename document:
      1. Invalidate file
      2. Mark dirty
      3. Spawn compiler (force)

   - Delete document:
      1. Invalidate file
      2. Mark dirty

   - Language request:
      1. Look up and return result

3. Compiler is spawned:

   1. Determine main file
   1. Determine stale files to clear
   1. Run build process and intercept AST
   1. Upsert where not invalidated
   1. Gracefully handle errors
