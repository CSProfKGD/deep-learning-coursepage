# Deep Learning Course Website

A modern static course website for **A Visual and Technical Journey Into Deep Learning**.

## Project Structure

- `index.html` contains the semantic page shell.
- `styles.css` defines the responsive visual system, dark/light themes, instructor portrait treatment, and lecture card design.
- `script.js` loads course data, renders lecture cards, filters categories, and persists theme choice.
- `data/course.json` is the single local content source for lectures, textbooks, resources, and instructor links.
- `data/course-data.js` mirrors `data/course.json` for browsers that block JSON loading from `file://`.
- `screenshots/` stores validation screenshots generated during review.

## Local Development

Run a local static server from this folder:

```bash
python3 -m http.server 8000
```

Then open:

```text
http://localhost:8000
```

You can also open `index.html` directly in Safari or Chrome. The page includes `data/course-data.js` as a fallback for browsers that block `fetch()` access to `data/course.json` from `file://`.

## Updating Lectures

Update lectures only in `data/course.json`.

Each lecture should include:

- `category`
- `lectureNumber`
- `catchyTitle`
- `originalLectureTitle`
- `description`
- `slidesUrl`
- `videoUrl`
- `status`

Use the York course page as the source of truth:

```text
https://www.eecs.yorku.ca/~kosta/Courses/EECS6322/
```

Do not invent URLs. If a resource is missing from the York page, set the URL to `null` and the card will show `Coming Soon`.

After changing `data/course.json`, regenerate the direct-open fallback:

```bash
node -e "const fs=require('fs'); const json=fs.readFileSync('data/course.json','utf8'); JSON.parse(json); fs.writeFileSync('data/course-data.js', 'window.COURSE_DATA = '+json+';\\n')"
```

## Replacing The Instructor Portrait

The hero uses `assets/KGD-profile.png` for the instructor portrait. Replace that image file with an approved updated portrait when needed, and keep the image circular with meaningful `alt` text.

## Automated Safari Website Recording

This project includes `record_safari_scroll.sh`, a macOS automation for creating a smooth Safari walkthrough video of the public course page:

```text
https://csprofkgd.github.io/deep-learning-coursepage/
```

The script opens Safari fresh, closes extra windows and tabs, loads only the target page, positions the browser window, waits at the top for 15 seconds, and performs a 90-second `requestAnimationFrame` scroll with cubic ease-in/ease-out motion. When supported by the installed macOS version, it records automatically with the built-in `screencapture` video mode and saves a timestamped `.mov` file to the Desktop.

If automatic capture is unavailable or blocked by permissions, the script falls back to a guided QuickTime workflow while still automating Safari setup and page scrolling.

### Installation

Make the script executable:

```bash
chmod +x record_safari_scroll.sh
```

### Running

Run from the project folder:

```bash
./record_safari_scroll.sh
```

The default output path is:

```text
~/Desktop/deep_learning_coursepage_YYYYMMDD_HHMMSS.mov
```

### Permissions

macOS may require these permissions before automation works reliably:

- Accessibility: allow Terminal, iTerm, or the shell application running the script.
- Screen Recording: allow Terminal for automatic `screencapture` recording and QuickTime Player for manual fallback.
- Automation: allow Terminal to control Safari.
- QuickTime Automation: allow Terminal to control QuickTime Player if using the manual fallback workflow.

Grant permissions in:

```text
System Settings -> Privacy & Security
```

If macOS prompts during the first run, grant permission and run the script again.

### Mouse Pointer Hiding

The mouse pointer should not appear in the final video.

The script tries to move the pointer away automatically if the optional `cliclick` command-line helper is installed. macOS does not provide a reliable built-in shell command for moving the pointer, so if `cliclick` is unavailable the script pauses and asks you to move the pointer to the bottom-right corner of the screen, outside the Safari window.

After the countdown begins, do not touch the mouse. The scroll is performed with JavaScript, not mouse wheel events, drag scrolling, keyboard scrolling, or Page Down.

### Customization

Edit the variables at the top of `record_safari_scroll.sh`:

```bash
URL="https://csprofkgd.github.io/deep-learning-coursepage/"
INITIAL_PAUSE_SECONDS=15
SCROLL_DURATION_SECONDS=90
WINDOW_WIDTH=1600
WINDOW_HEIGHT=1000
OUTPUT_NAME="deep_learning_coursepage"
```

The script also defines `WINDOW_X` and `WINDOW_Y` for positioning Safari on screen.

### Recording Behavior

The generated scroll script uses:

- A stationary 15-second hold at the top.
- `requestAnimationFrame`.
- Cubic ease-in/ease-out motion.
- A full-page scroll from `window.scrollTo(0, 0)` to the page bottom.
- No simulated wheel, drag, keyboard, or Page Down input.

Approximate video duration with defaults:

```text
15 seconds pause + 90 seconds scroll = 105 seconds
```

### Troubleshooting

Safari not responding to automation:

- Grant Automation permission for Terminal controlling Safari.
- Quit Safari manually and rerun the script.
- Confirm Safari is installed in `/Applications` or registered with Launch Services.

QuickTime or automatic recording not starting:

- Grant Screen Recording permission to Terminal and QuickTime Player.
- If automatic `screencapture -v` is unavailable on your macOS version, use the guided QuickTime fallback.
- Start QuickTime recording manually when prompted, then press Return in Terminal.

macOS permission prompts appear:

- Accept the prompt, then rerun the script.
- Some permissions require restarting Terminal after enabling them.

Mouse pointer appears in the recording:

- Move the pointer to the bottom-right corner before the recording countdown completes.
- Do not touch the mouse during recording.
- Optionally install `cliclick` so the script can move the pointer automatically.

Page not scrolling:

- Ensure Safari has loaded the public course page.
- Grant Automation permission for Terminal controlling Safari.
- Rerun the script after the page loads successfully.

Extra tabs appearing:

- The script quits Safari, relaunches it, closes extra windows, and keeps one tab.
- If Safari restores windows because of system settings, rerun the script after granting Automation permission.
