import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { afterEach, describe, expect, it } from 'vitest'
import App from './App'

function renderPortal() {
  return render(<BrowserRouter><App /></BrowserRouter>)
}

afterEach(() => window.history.replaceState({}, '', '/login'))

describe('portal access and disconnected preview', () => {
  it('fails closed at sign-in and provides no default credentials', () => {
    renderPortal()
    expect(screen.getByText(/Admin authentication is not configured/)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Sign in' })).toBeDisabled()
  })

  it('redirects direct protected-page access to login', async () => {
    window.history.replaceState({}, '', '/app/customers')
    renderPortal()
    await waitFor(() => expect(screen.getByRole('heading', { name: 'Sign in to operations' })).toBeInTheDocument())
  })

  it('shows backend requirements instead of fabricated dashboard metrics', async () => {
    renderPortal()
    fireEvent.click(screen.getByRole('button', { name: 'Open disconnected interface preview' }))
    await waitFor(() => expect(screen.getByRole('heading', { name: 'Overview' })).toBeInTheDocument())
    expect(screen.getByText(/Preview mode never requests live admin data/)).toBeInTheDocument()
    expect(screen.queryByText('12,430')).not.toBeInTheDocument()
    expect(screen.getByText('UNCONNECTED PREVIEW')).toBeInTheDocument()
  })
})
