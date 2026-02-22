import { useState, useEffect } from "react"

// React 데모 컴포넌트 - 마운트/언마운트 및 인터랙션 검증용
export default function ReactDemo() {
  const [count, setCount] = useState(0)
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
    return () => setMounted(false)
  }, [])

  return (
    <div style={{ padding: "2rem", fontFamily: "sans-serif" }}>
      <h1>React 데모 컴포넌트</h1>
      <p>마운트 상태: {mounted ? "활성" : "비활성"}</p>
      <p>카운터: {count}</p>
      <button
        onClick={() => setCount(c => c + 1)}
        style={{
          padding: "0.5rem 1rem",
          backgroundColor: "#3b82f6",
          color: "white",
          borderRadius: "0.375rem",
          border: "none",
          cursor: "pointer",
        }}
      >
        증가
      </button>
    </div>
  )
}
