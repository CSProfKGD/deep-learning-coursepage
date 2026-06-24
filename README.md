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
