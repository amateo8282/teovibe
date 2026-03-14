// STYL-04: 커스텀 FontSize extension
// @tiptap/extension-font-size는 v3.x 전용이므로 Extension.create()로 직접 구현
// TextStyle mark 위에서 동작하며 font-size 인라인 스타일을 적용한다
import { Extension } from "@tiptap/core"

export const FontSize = Extension.create({
  name: "fontSize",

  addOptions() {
    return {
      types: ["textStyle"],
    }
  },

  addGlobalAttributes() {
    return [
      {
        types: this.options.types,
        attributes: {
          fontSize: {
            default: null,
            // CSS 값에서 따옴표 제거 후 빈 문자열이면 null 반환
            parseHTML: (element) =>
              element.style.fontSize.replace(/['"]+/g, "") || null,
            renderHTML: (attributes) => {
              if (!attributes.fontSize) return {}
              return { style: `font-size: ${attributes.fontSize}` }
            },
          },
        },
      },
    ]
  },

  addCommands() {
    return {
      // 선택 텍스트에 폰트 크기 적용 (예: "16px")
      setFontSize:
        (fontSize) =>
        ({ chain }) =>
          chain().setMark("textStyle", { fontSize }).run(),

      // 폰트 크기 해제 — 빈 textStyle mark도 함께 제거
      unsetFontSize:
        () =>
        ({ chain }) =>
          chain()
            .setMark("textStyle", { fontSize: null })
            .removeEmptyTextStyle()
            .run(),
    }
  },
})
