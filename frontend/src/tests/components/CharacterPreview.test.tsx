import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect } from 'vitest';
import CharacterPreview from '../../components/CharacterPreview';

const STATS = [
  { part: 'chest', level: 2, potential: 50 },
  { part: 'back', level: 1, potential: 30 },
  { part: 'legs', level: 1, potential: 20 },
  { part: 'shoulders', level: 1, potential: 10 },
  { part: 'arms', level: 1, potential: 5 },
  { part: 'core', level: 1, potential: 0 },
  { part: 'stamina', level: 1, potential: 0 },
];

describe('CharacterPreview', () => {
  it('renders username initial in avatar', () => {
    render(<CharacterPreview username="alice" />);
    expect(screen.getByText('A')).toBeTruthy();
  });

  it('renders username', () => {
    render(<CharacterPreview username="alice" />);
    expect(screen.getByText('alice')).toBeTruthy();
  });

  it('shows summary stats when body_stats provided', () => {
    render(<CharacterPreview username="bob" body_stats={STATS} />);
    // Total level = 2+1*6 = 8
    expect(screen.getByText(/Lv\.8/)).toBeTruthy();
  });

  it('expands to show a per-part level on click', async () => {
    const user = userEvent.setup();
    render(<CharacterPreview username="carol" body_stats={STATS} />);
    const card = screen.getByText('carol').closest('div')!;
    await user.click(card);
    expect(screen.getByText('Lv.2')).toBeTruthy();
  });
  it('renders question mark initial for empty username', () => {
    render(<CharacterPreview username="" />);
    expect(screen.getByText('?')).toBeTruthy();
  });
  it('renders question mark initial for empty username', () => {
    render(<CharacterPreview username="" />);
    expect(screen.getByText('?')).toBeTruthy();
  });

  it('does not crash with no body_stats', () => {
    render(<CharacterPreview username="dave" />);
    expect(screen.getByText('dave')).toBeTruthy();
  });

  it('near-breakthrough stat has 90+ potential', () => {
    const nearBreak = [
      ...STATS.slice(0, -1),
      { part: 'stamina', level: 1, potential: 92 },
    ];
    // Just checking it renders without error
    render(<CharacterPreview username="eve" body_stats={nearBreak} />);
    expect(screen.getByText('eve')).toBeTruthy();
  });

  it('renders avatar image when avatar_url is provided', () => {
    render(<CharacterPreview username="frank" avatar_url="/assets/avatars/stage_1.svg" />);
    const img = screen.getByAltText('frank') as HTMLImageElement;
    expect(img).toBeTruthy();
    expect(img.src).toContain('/assets/avatars/stage_1.svg');
  });

  it('falls back to initial when avatar image error occurs', async () => {
    render(<CharacterPreview username="grace" avatar_url="/assets/avatars/stage_99.svg" />);
    const img = screen.getByAltText('grace');
    
    // Trigger image error
    const fireEvent = await import('@testing-library/react').then(m => m.fireEvent);
    fireEvent.error(img);
    
    // Now it should show initial "G"
    expect(screen.getByText('G')).toBeTruthy();
  });

  it('renders characterName when characterName is provided', () => {
    render(<CharacterPreview username="alice" characterName="SuperAlice" />);
    expect(screen.getByText('SuperAlice')).toBeTruthy();
    expect(screen.queryByText('alice')).toBeNull();
  });

  it('displays stage and next goal when expanded', async () => {
    const user = userEvent.setup();
    render(<CharacterPreview username="bob" body_stats={STATS} />);
    const card = screen.getByText('bob').closest('div')!;
    await user.click(card);

    expect(screen.getByText('Stage 1')).toBeTruthy();
    expect(screen.getByText(/Lv\.15/)).toBeTruthy();
  });

  it('shows explicit XP and growing status for positive potential', async () => {
    const user = userEvent.setup();
    render(<CharacterPreview username="xp-user" body_stats={[{ part: 'chest', level: 1, potential: 1 }]} />);
    await user.click(screen.getByText('xp-user').closest('div')!);
    expect(screen.getByText('XP 1/100')).toBeTruthy();
    expect(screen.getByText('Growing')).toBeTruthy();
  });

  it('uses a text status at the level-up boundary', async () => {
    const user = userEvent.setup();
    render(<CharacterPreview username="boundary" body_stats={[{ part: 'chest', level: 1, potential: 90 }]} />);
    await user.click(screen.getByText('boundary').closest('div')!);
    expect(screen.getByText('Near level-up')).toBeTruthy();
    expect(screen.getByLabelText('90 XP out of 100')).toBeTruthy();
  });

  it('handles zero potential without relying on color', async () => {
    const user = userEvent.setup();
    render(<CharacterPreview username="empty-xp" body_stats={[{ part: 'chest', level: 1, potential: 0 }]} />);
    await user.click(screen.getByText('empty-xp').closest('div')!);
    expect(screen.getByText('Ready to grow')).toBeTruthy();
    expect(screen.getByText('XP 0/100')).toBeTruthy();
  });

  it('has correct accessibility attributes', async () => {
    const user = userEvent.setup();
    render(<CharacterPreview username="carol" body_stats={STATS} />);
    const card = screen.getByText('carol').closest('div')!;
    
    expect(card.getAttribute('role')).toBe('button');
    expect(card.getAttribute('tabIndex')).toBe('0');
    expect(card.getAttribute('aria-expanded')).toBe('false');

    await user.click(card);
    expect(card.getAttribute('aria-expanded')).toBe('true');

    // Potential progress bar should have role progressbar and ARIA attributes
    const progressbar = screen.getAllByRole('progressbar')[0];
    expect(progressbar).toBeTruthy();
    expect(progressbar.getAttribute('aria-valuenow')).toBe('50');
  });
});
