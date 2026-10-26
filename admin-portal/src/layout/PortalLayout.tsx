import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { Link as RouterLink, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { Avatar, Box, Button, Chip, Dialog, DialogContent, Divider, Drawer, IconButton, InputAdornment, List, ListItemButton, ListItemIcon, ListItemText, TextField, Toolbar, Typography, Tooltip } from '@mui/material'
import { AccountBalanceWalletOutlined, AdminPanelSettingsOutlined, AssessmentOutlined, ArticleOutlined, BarChartRounded, ChevronLeftRounded, ChevronRightRounded, DashboardRounded, DarkModeOutlined, HealthAndSafetyOutlined, LightModeOutlined, MenuRounded, NotificationsOutlined, PeopleAltOutlined, SettingsOutlined, ShieldOutlined, TableChartOutlined, TimelineRounded, TuneRounded, WorkHistoryOutlined, StorageOutlined, ApiOutlined, LanOutlined, DnsOutlined, SearchRounded, KeyboardArrowDownRounded, HelpOutlineRounded, CloseRounded } from '@mui/icons-material'
import { useAuth } from '../auth/AuthContext'
import type { AdminPermission } from '../api/adminApi'
import { adminApi } from '../api/adminApi'
import { PreviewProvider } from './PreviewContext'
import { useColorMode } from './ColorModeContext'

const widthWide = 258
type Item = { label: string; href: string; icon: ReactNode; permission?: AdminPermission; pending?: boolean }
const groups: Array<{ title: string; items: Item[] }> = [
  { title: 'Workspace', items: [{ label: 'Overview', href: '/dashboard', icon: <DashboardRounded />, permission: 'dashboard.view' }] },
  { title: 'Operations', items: [{ label: 'Transactions', href: '/transactions', icon: <AccountBalanceWalletOutlined />, permission: 'transactions.view' }, { label: 'Transaction monitoring', href: '/monitoring/transactions', icon: <TimelineRounded />, permission: 'monitoring.view', pending: true }] },
  { title: 'Customers', items: [{ label: 'Customer directory', href: '/customers', icon: <PeopleAltOutlined />, permission: 'customers.view' }] },
  { title: 'Services', items: [{ label: 'Notifications', href: '/notifications', icon: <NotificationsOutlined />, permission: 'notifications.view' }, { label: 'Reports', href: '/reports', icon: <AssessmentOutlined />, permission: 'reports.view' }] },
  { title: 'Monitoring', items: [{ label: 'Overview', href: '/monitoring/overview', icon: <HealthAndSafetyOutlined />, permission: 'monitoring.view', pending: true }, { label: 'Transactions', href: '/monitoring/transactions', icon: <TimelineRounded />, permission: 'monitoring.view', pending: true }, { label: 'Application & services', href: '/monitoring/services', icon: <DnsOutlined />, permission: 'monitoring.view', pending: true }, { label: 'APIs', href: '/monitoring/apis', icon: <ApiOutlined />, permission: 'monitoring.view', pending: true }, { label: 'Servers', href: '/monitoring/servers', icon: <LanOutlined />, permission: 'monitoring.view', pending: true }, { label: 'Database', href: '/monitoring/database', icon: <StorageOutlined />, permission: 'monitoring.view', pending: true }, { label: 'Network', href: '/monitoring/network', icon: <LanOutlined />, permission: 'monitoring.view', pending: true }, { label: 'Alerts', href: '/monitoring/alerts', icon: <TuneRounded />, permission: 'monitoring.view', pending: true }, { label: 'Grafana', href: '/monitoring/grafana', icon: <BarChartRounded />, permission: 'monitoring.view', pending: true }, { label: 'Zabbix', href: '/monitoring/zabbix', icon: <TableChartOutlined />, permission: 'monitoring.view', pending: true }] },
  { title: 'Security', items: [{ label: 'Administrators & roles', href: '/security/admins', icon: <AdminPanelSettingsOutlined />, permission: 'users.view', pending: true }, { label: 'Audit log', href: '/security/audit', icon: <WorkHistoryOutlined />, permission: 'audit.view', pending: true }] },
  { title: 'Configuration', items: [{ label: 'Application settings', href: '/configuration', icon: <SettingsOutlined />, permission: 'configuration.view' }, { label: 'Dynamic content', href: '/configuration/content', icon: <ArticleOutlined />, permission: 'configuration.view' }] },
]

export function PortalLayout({ preview = false }: { preview?: boolean }) {
  const [mobileOpen, setMobileOpen] = useState(false)
  const [collapsed, setCollapsed] = useState(false)
  const [closed, setClosed] = useState<string[]>([])
  const [searchOpen, setSearchOpen] = useState(false)
  const [search, setSearch] = useState('')
  const { session, signOut } = useAuth()
  const location = useLocation()
  const navigate = useNavigate()
  const prefix = preview ? '/preview' : '/app'
  const path = location.pathname.replace('/preview', '').replace('/app', '') || '/dashboard'
  const drawerWidth = collapsed ? 72 : widthWide
  const { mode, toggle: toggleColorMode } = useColorMode()
  const allItems = useMemo(() => groups.flatMap(group => group.items.map(item => ({ ...item, group: group.title }))), [])
  const currentItem = [...allItems].sort((a, b) => b.href.length - a.href.length).find(item => path === item.href || path.startsWith(`${item.href}/`))
  const results = allItems.filter(item => `${item.label} ${item.group}`.toLowerCase().includes(search.trim().toLowerCase()))

  useEffect(() => {
    const handleShortcut = (event: KeyboardEvent) => {
      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') { event.preventDefault(); setSearchOpen(true) }
      if (event.key === 'Escape') setSearchOpen(false)
    }
    window.addEventListener('keydown', handleShortcut)
    return () => window.removeEventListener('keydown', handleShortcut)
  }, [])

  const openModule = (href: string) => { navigate(`${prefix}${href}`); setSearchOpen(false); setSearch(''); setMobileOpen(false) }

  const navigation = <Box className="sidebar-content">
    <Box className="brand-block"><Avatar className="brand-mark">PA</Avatar>{!collapsed && <Box><Typography className="brand-name">PayAfghan</Typography><Typography className="brand-caption">OPERATIONS CONSOLE</Typography></Box>}</Box>
    <Divider />
    <Box className="nav-scroll">{groups.map(group => {
      const isClosed = closed.includes(group.title)
      return <Box className="nav-group" key={group.title}>
        {!collapsed && <button className="nav-group-toggle" onClick={() => setClosed(old => isClosed ? old.filter(value => value !== group.title) : [...old, group.title])}>{group.title}<KeyboardArrowDownRounded className={isClosed ? 'group-chevron is-closed' : 'group-chevron'} /></button>}
        {(collapsed || !isClosed) && <List disablePadding>{group.items.map(item => {
          const allowed = preview || !item.permission || !!session?.permissions.includes(item.permission)
          const selected = path === item.href || path.startsWith(`${item.href}/`)
          return <Tooltip key={item.href} title={collapsed ? item.label : ''} placement="right"><span><ListItemButton disabled={!allowed && !!session} selected={selected} component={RouterLink} to={`${prefix}${item.href}`} onClick={() => setMobileOpen(false)} className="nav-item"><ListItemIcon>{item.icon}</ListItemIcon>{!collapsed && <><ListItemText primary={item.label} /><span className="nav-tail">{item.pending && <i className="integration-dot" />}{selected && <ChevronRightRounded fontSize="small" />}</span></>}</ListItemButton></span></Tooltip>
        })}</List>}
      </Box>
    })}</Box>
    {!collapsed && <Box className="sidebar-foot"><Box className="security-mark"><ShieldOutlined fontSize="small" /></Box><Box><Typography variant="caption" display="block" fontWeight={700}>Secure workspace</Typography><Typography variant="caption">Permissions enforced by backend</Typography></Box></Box>}
  </Box>

  return <Box className="portal-frame">
    <Box component="nav" sx={{ width: { md: drawerWidth }, flexShrink: { md: 0 } }}>
      <Drawer variant="temporary" open={mobileOpen} onClose={() => setMobileOpen(false)} ModalProps={{ keepMounted: true }} sx={{ display: { xs: 'block', md: 'none' }, '& .MuiDrawer-paper': { width: widthWide } }}>{navigation}</Drawer>
      <Drawer variant="permanent" open sx={{ display: { xs: 'none', md: 'block' }, '& .MuiDrawer-paper': { width: drawerWidth, boxSizing: 'border-box', overflowX: 'hidden', transition: 'width .2s' } }}>{navigation}</Drawer>
    </Box>
    <Box className="main-frame" sx={{ width: { md: `calc(100% - ${drawerWidth}px)` }, ml: { md: `${drawerWidth}px` } }}>
      <Box component="header" className="topbar"><Toolbar className="topbar-inner"><IconButton onClick={() => setMobileOpen(true)} className="mobile-menu" aria-label="Open menu"><MenuRounded /></IconButton><Box className="breadcrumbs"><Typography variant="caption">{currentItem?.group ?? 'PAYAFGHAN'}</Typography><ChevronRightRounded fontSize="small" /><Typography variant="body2">{currentItem?.label ?? 'Operations'}</Typography></Box><Box className="topbar-spacer" /><Button className="global-search" variant="outlined" startIcon={<SearchRounded />} onClick={() => setSearchOpen(true)}><span>Search modules</span><kbd>Ctrl K</kbd></Button><Chip className="environment-chip" size="small" color={preview ? 'warning' : 'default'} variant={preview ? 'filled' : 'outlined'} label={preview ? 'PREVIEW' : adminApi.configured ? 'API ONLINE' : 'API OFFLINE'} /><Tooltip title={`Switch to ${mode === 'light' ? 'dark' : 'light'} mode`}><IconButton className="header-action" onClick={toggleColorMode} aria-label="Toggle color mode">{mode === 'light' ? <DarkModeOutlined /> : <LightModeOutlined />}</IconButton></Tooltip><Tooltip title="Help and integration status"><IconButton className="header-action help-action" aria-label="Help"><HelpOutlineRounded /></IconButton></Tooltip><Divider orientation="vertical" flexItem className="top-divider" /><Box className="profile-button"><Avatar className="admin-avatar">{session?.displayName.slice(0, 1) ?? 'A'}</Avatar><Box className="admin-identity"><Typography variant="body2" fontWeight={700}>{session?.displayName ?? 'No admin session'}</Typography><Typography variant="caption" color="text.secondary">{session?.role ?? (preview ? 'Preview only' : 'Unauthenticated')}</Typography></Box></Box>{session && <Button size="small" className="signout-button" onClick={() => void signOut().then(() => navigate('/login'))}>Sign out</Button>}<IconButton onClick={() => setCollapsed(value => !value)} className="collapse-button" aria-label="Collapse sidebar">{collapsed ? <ChevronRightRounded /> : <ChevronLeftRounded />}</IconButton></Toolbar></Box>
      {preview && <Box className="preview-banner"><Typography variant="body2"><strong>Disconnected preview.</strong> No production data is displayed; live modules require a protected backend.</Typography></Box>}
      <PreviewProvider preview={preview}><Box component="main" className="page-content"><Outlet /></Box></PreviewProvider>
    </Box>
    <Dialog open={searchOpen} onClose={() => setSearchOpen(false)} fullWidth maxWidth="sm" PaperProps={{ className: 'command-dialog' }}><DialogContent><Box className="command-input"><TextField autoFocus fullWidth placeholder="Search pages and modules…" value={search} onChange={event => setSearch(event.target.value)} InputProps={{ startAdornment: <InputAdornment position="start"><SearchRounded /></InputAdornment>, endAdornment: <InputAdornment position="end"><IconButton size="small" onClick={() => setSearchOpen(false)} aria-label="Close search"><CloseRounded /></IconButton></InputAdornment> }} /></Box><Typography className="command-label">{search ? `${results.length} RESULTS` : 'QUICK NAVIGATION'}</Typography><List className="command-results">{results.map(item => <ListItemButton key={`${item.group}-${item.href}`} onClick={() => openModule(item.href)}><ListItemIcon>{item.icon}</ListItemIcon><ListItemText primary={item.label} secondary={item.group} /><ChevronRightRounded color="disabled" /></ListItemButton>)}{!results.length && <Box className="command-empty"><SearchRounded /><Typography fontWeight={700}>No modules found</Typography><Typography variant="body2" color="text.secondary">Try a different page or service name.</Typography></Box>}</List><Box className="command-footer"><span><kbd>↑</kbd><kbd>↓</kbd> browse</span><span><kbd>esc</kbd> close</span></Box></DialogContent></Dialog>
  </Box>
}
