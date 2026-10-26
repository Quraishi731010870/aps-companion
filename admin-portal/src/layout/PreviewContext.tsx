import { createContext, useContext, type ReactNode } from 'react'

const PreviewContext = createContext(false)

export function PreviewProvider({ preview, children }: { preview: boolean; children: ReactNode }) {
  return <PreviewContext.Provider value={preview}>{children}</PreviewContext.Provider>
}

// eslint-disable-next-line react-refresh/only-export-components
export function usePreviewMode() { return useContext(PreviewContext) }
