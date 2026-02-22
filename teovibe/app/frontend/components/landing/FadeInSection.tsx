import { motion } from "motion/react"

// 스크롤 시 fade-in 등장 애니메이션 래퍼 컴포넌트
// whileInView 패턴: 뷰포트 진입 시 한 번만 실행 (once: true)
interface FadeInSectionProps {
  children: React.ReactNode
  className?: string
}

export default function FadeInSection({ children, className }: FadeInSectionProps) {
  return (
    <motion.div
      className={className}
      initial={{ opacity: 0, y: 32 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, amount: 0.1 }}
      transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
    >
      {children}
    </motion.div>
  )
}
