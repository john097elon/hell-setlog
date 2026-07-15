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

  it('expands to show per-part stats on click', async () => {
    const user = userEvent.setup();
    render(<CharacterPreview username="carol" body_stats={STATS} />);
    const card = screen.getByText('carol').closest('div')!.parentElement!;
    await user.click(card);
    // Part labels should appear after expanding
    expect(screen.getByText('가슴')).toBeTruthy();
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
});
