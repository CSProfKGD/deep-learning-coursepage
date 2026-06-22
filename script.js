const state = {
  lectures: [],
  activeCategory: "All"
};

const selectors = {
  categoryNav: document.querySelector("[data-category-nav]"),
  lectureGrid: document.querySelector("[data-lecture-grid]"),
  socialLinks: document.querySelector("[data-social-links]"),
  textbookList: document.querySelector("[data-textbook-list]"),
  resourceList: document.querySelector("[data-resource-list]"),
  themeToggle: document.querySelector(".theme-toggle"),
  toggleText: document.querySelector(".toggle-text")
};

const soonText = "Coming Soon";

function createElement(tag, className, text) {
  const element = document.createElement(tag);
  if (className) element.className = className;
  if (text) element.textContent = text;
  return element;
}

function externalLink(label, href, className = "link-chip") {
  if (!href) {
    const chip = createElement("span", "status-chip", soonText);
    chip.setAttribute("aria-label", `${label} coming soon`);
    return chip;
  }

  const link = createElement("a", className, label);
  link.href = href;
  link.target = "_blank";
  link.rel = "noopener noreferrer";
  return link;
}

const socialIcons = {
  Homepage:
    '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 11.5 12 4l9 7.5"/><path d="M5.5 10.5V20h13v-9.5"/><path d="M9.5 20v-6h5v6"/></svg>',
  X:
    '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M13.9 10.5 21.3 2h-1.8l-6.4 7.4L8 2H2l7.8 11.3L2 22h1.8l6.8-7.8L16 22h6l-8.1-11.5Zm-2.4 2.7-.8-1.1L4.4 3.3h2.8l5 7 .8 1.1 6.6 9.3h-2.8l-5.3-7.5Z"/></svg>',
  LinkedIn:
    '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M20.4 3H3.6c-.9 0-1.6.7-1.6 1.6v16.8c0 .9.7 1.6 1.6 1.6h16.8c.9 0 1.6-.7 1.6-1.6V4.6c0-.9-.7-1.6-1.6-1.6ZM8.1 19.7H5V9.9h3.1v9.8ZM6.6 8.5a1.8 1.8 0 1 1 0-3.6 1.8 1.8 0 0 1 0 3.6Zm13.1 11.2h-3.1v-4.8c0-1.1 0-2.6-1.6-2.6s-1.8 1.2-1.8 2.5v4.9h-3.1V9.9h3v1.3h.1c.4-.8 1.4-1.6 2.9-1.6 3.1 0 3.6 2 3.6 4.7v5.4Z"/></svg>'
};

function socialIconLink(label, href, iconKey) {
  const link = externalLink(label, href, "social-icon-link");
  link.setAttribute("aria-label", label);
  link.title = label;
  link.innerHTML = `${socialIcons[iconKey]}<span class="visually-hidden">${label}</span>`;
  return link;
}

function renderSocialLinks(instructor) {
  selectors.socialLinks.replaceChildren(
    socialIconLink("Homepage", instructor.homepageUrl, "Homepage"),
    socialIconLink("X", instructor.twitterUrl, "X"),
    socialIconLink("LinkedIn", instructor.linkedinUrl, "LinkedIn")
  );
  // TODO: Update social links when the York source page provides additional official profiles.
}

function renderCategories() {
  const categories = ["All", ...new Set(state.lectures.map((lecture) => lecture.category))];
  const buttons = categories.map((category) => {
    const button = createElement("button", "category-button", category);
    button.type = "button";
    button.setAttribute("aria-pressed", String(category === state.activeCategory));
    button.addEventListener("click", () => {
      state.activeCategory = category;
      renderCategories();
      renderLectures();
    });
    return button;
  });

  selectors.categoryNav.replaceChildren(...buttons);
}

function renderLectures() {
  const lectures =
    state.activeCategory === "All"
      ? state.lectures
      : state.lectures.filter((lecture) => lecture.category === state.activeCategory);

  const cards = lectures.map((lecture) => {
    const article = createElement("article", "lecture-card");
    article.setAttribute("data-status", lecture.status);
    const isGanLecture = lecture.originalLectureTitle.includes("Generative Adversarial Network");
    if (isGanLecture) {
      article.classList.add("gan-card");
    }

    const top = createElement("div", "card-top");
    const meta = createElement("div", "card-meta");
    meta.append(
      createElement("span", "number", String(lecture.lectureNumber).padStart(2, "0")),
      createElement("span", null, lecture.category)
    );

    const title = createElement("h3", null, lecture.catchyTitle);
    const original = createElement("p", "original-title", lecture.originalLectureTitle);
    const description = createElement("p", "description", lecture.description);
    top.append(meta, title, original, description);

    const bottom = createElement("div", "card-bottom");
    const actions = createElement("div", "card-actions");
    actions.append(
      externalLink("Slides", lecture.slidesUrl),
      externalLink("Video", lecture.videoUrl)
    );
    bottom.append(actions);

    article.append(top, bottom);

    if (isGanLecture) {
      const revealSlot = createElement("div", "gan-reveal-slot");
      const dialogue = createElement("div", "gan-dialogue");
      dialogue.setAttribute("aria-hidden", "true");
      dialogue.innerHTML = `
        <p><strong>Generator:</strong></p>
        <p>"I made this image."</p>
        <p><strong>Discriminator:</strong></p>
        <p>"It's fake."</p>
        <p><strong>Schmidhuber:</strong></p>
        <p>"Please see my earlier work."</p>
      `;

      article.addEventListener("click", (event) => {
        if (event.target.closest("a, button")) return;
        article.classList.toggle("is-revealed");
      });
      article.addEventListener("pointerover", (event) => {
        if (event.pointerType === "touch") return;
        article.classList.toggle("is-hover-revealed", !event.target.closest("a, button"));
      });
      article.addEventListener("pointerleave", () => {
        article.classList.remove("is-hover-revealed");
      });

      revealSlot.append(dialogue);
      bottom.append(revealSlot);
    }

    return article;
  });

  selectors.lectureGrid.replaceChildren(...cards);
}

function renderTextbooks(textbooks) {
  const items = textbooks.map((book) => {
    const item = createElement("article", "resource-item");
    item.append(
      createElement("strong", null, book.title),
      createElement("p", null, book.authors)
    );

    const links = createElement("div", "card-actions");
    links.append(externalLink("Free online", book.freeUrl), externalLink("Publisher", book.publisherUrl));
    item.append(links);
    return item;
  });

  selectors.textbookList.replaceChildren(...items);
}

function renderResources(resources) {
  const categories = [
    {
      title: "Mathematics",
      resources: resources.filter((resource) =>
        [
          "The Matrix Calculus You Need for Deep Learning",
          "Basic Linear algebra review",
          "Linear algebra review and reference",
          "The Matrix Cookbook"
        ].includes(resource.title)
      )
    },
    {
      title: "Programming",
      resources: resources.filter((resource) => resource.title === "Python NumPy tutorial")
    }
  ];

  const items = categories.map((category) => {
    const group = createElement("div", "resource-group");
    group.append(createElement("h4", null, category.title));

    const list = createElement("ul", "compact-resource-list");
    const rows = category.resources.map((resource) => {
      const item = createElement("li");
      const link = createElement("a", null, resource.title);
      link.href = resource.url;
      link.target = "_blank";
      link.rel = "noopener noreferrer";
      item.append(link);
      return item;
    });

    list.append(...rows);
    group.append(list);
    return group;
  });

  selectors.resourceList.replaceChildren(...items);
}

function syncThemeButton() {
  const isDark = document.documentElement.dataset.theme !== "light";
  selectors.themeToggle.setAttribute("aria-label", `Switch to ${isDark ? "light" : "dark"} theme`);
  selectors.toggleText.textContent = isDark ? "Light" : "Dark";
}

function setupThemeToggle() {
  syncThemeButton();
  selectors.themeToggle.addEventListener("click", () => {
    const nextTheme = document.documentElement.dataset.theme === "light" ? "dark" : "light";
    document.documentElement.dataset.theme = nextTheme;
    localStorage.setItem("course-theme", nextTheme);
    syncThemeButton();
  });
}

async function loadCourse() {
  if (window.COURSE_DATA && window.location.protocol === "file:") {
    return window.COURSE_DATA;
  }

  const response = await fetch("data/course.json");
  if (!response.ok) {
    throw new Error(`Unable to load course data: ${response.status}`);
  }

  return response.json();
}

function renderCourse(course) {
  state.lectures = course.lectures;

  renderSocialLinks(course.meta.instructor);
  renderCategories();
  renderLectures();
  renderTextbooks(course.textbooks);
  renderResources(course.resources);
}

setupThemeToggle();
loadCourse()
  .then(renderCourse)
  .catch((error) => {
    if (window.COURSE_DATA) {
      renderCourse(window.COURSE_DATA);
      return;
    }

    selectors.lectureGrid.textContent = "Course data could not be loaded.";
    console.error(error);
  });
