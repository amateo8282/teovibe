// 링크 미리보기 노드 (OG 메타데이터 기반)
// ActionText에 <figure data-link-preview> HTML로 직렬화되어 저장됨
import { Node, mergeAttributes } from "@tiptap/core"

export const LinkPreview = Node.create({
  name: "linkPreview",
  group: "block",
  atom: true,
  draggable: true,

  addAttributes() {
    return {
      href:        { default: null },
      title:       { default: null },
      description: { default: null },
      imageUrl:    { default: null },
      siteName:    { default: null },
    }
  },

  parseHTML() {
    return [{
      tag: "figure[data-link-preview]",
      getAttrs: (el) => ({
        href:        el.getAttribute("data-href"),
        title:       el.getAttribute("data-title"),
        description: el.getAttribute("data-description"),
        imageUrl:    el.getAttribute("data-image-url"),
        siteName:    el.getAttribute("data-site-name"),
      }),
    }]
  },

  renderHTML({ HTMLAttributes }) {
    const { href, title, description, imageUrl, siteName } = HTMLAttributes

    let hostname = href || ""
    try { hostname = new URL(href).hostname } catch {}

    const inner = []
    if (imageUrl) {
      inner.push(["img", { src: imageUrl, alt: title || "", class: "link-preview-image" }])
    }

    const textParts = [["div", { class: "link-preview-title" }, title || href]]
    if (description) textParts.push(["div", { class: "link-preview-description" }, description])
    textParts.push(["div", { class: "link-preview-site" }, siteName || hostname])
    inner.push(["div", { class: "link-preview-content" }, ...textParts])

    return ["figure", mergeAttributes({
      "data-link-preview": "",
      "data-href":         href        || "",
      "data-title":        title       || "",
      "data-description":  description || "",
      "data-image-url":    imageUrl    || "",
      "data-site-name":    siteName    || "",
      class:               "link-preview-card",
    }), ["a", { href, target: "_blank", rel: "noopener noreferrer" }, ...inner]]
  },

  // 에디터 내 렌더링 (Light DOM 방식)
  addNodeView() {
    return ({ node }) => {
      const { href, title, description, imageUrl, siteName } = node.attrs

      let hostname = href || ""
      try { hostname = new URL(href).hostname } catch {}

      const dom = document.createElement("figure")
      dom.className = "link-preview-card"
      dom.contentEditable = "false"

      const escAttr = (s) => (s || "").replace(/"/g, "&quot;")
      const escHtml = (s) => (s || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")

      dom.innerHTML = `
        <a href="${escAttr(href)}" target="_blank" rel="noopener noreferrer">
          ${imageUrl ? `<img src="${escAttr(imageUrl)}" alt="${escAttr(title)}" class="link-preview-image" />` : ""}
          <div class="link-preview-content">
            <div class="link-preview-title">${escHtml(title || href)}</div>
            ${description ? `<div class="link-preview-description">${escHtml(description)}</div>` : ""}
            <div class="link-preview-site">${escHtml(siteName || hostname)}</div>
          </div>
        </a>
      `

      return { dom }
    }
  },

  addCommands() {
    return {
      insertLinkPreview: (attrs) => ({ commands }) => {
        return commands.insertContent({ type: this.name, attrs })
      },
    }
  },
})
