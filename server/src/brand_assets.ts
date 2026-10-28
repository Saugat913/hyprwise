// Hyprwise Official Brand Vector Assets (Derived from assets/brandings)
const outerPath = `M 264 711 L 264 302 C 264 246 306 207 365 185 C 387 177 404 190 404 212 L 404 393 C 449 360 498 338 550 338 C 666 338 758 414 758 527 L 758 710 C 758 769 719 811 659 811 C 626 811 604 797 584 768 L 530 687 C 523 676 516 676 509 687 L 453 766 C 433 795 409 811 376 811 C 309 811 264 770 264 711 Z`;
const innerPath = `M 302 599 C 339 557 391 513 449 480 C 486 459 520 448 552 454 C 607 463 639 501 639 548 L 639 647 C 639 666 631 679 620 679 C 612 679 606 671 600 662 L 557 605 C 545 589 533 590 521 606 L 480 664 C 472 676 465 681 458 681 C 444 681 441 665 440 648 L 435 539 C 387 556 339 583 302 599 Z`;

export const HYPRWISE_MARK_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" role="img" aria-label="Hyprwise mark">
  <path fill="#FF6500" fill-rule="evenodd" d="${outerPath} ${innerPath}"/>
</svg>`;

export const HYPRWISE_BADGE_SVG = `<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 1024 1024" role="img" aria-label="Hyprwise">
  <path fill="#FF6500" fill-rule="evenodd" d="${outerPath} ${innerPath}"/>
</svg>`;

export const HYPRWISE_FAVICON_SVG = `<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 1024 1024" role="img" aria-label="Hyprwise">
  <rect width="1024" height="1024" rx="220" fill="#FFFFFF"/>
  <path fill="#FF6500" fill-rule="evenodd" d="${outerPath} ${innerPath}"/>
</svg>`;

export const HYPRWISE_APP_ICON_DARK_SVG = `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024" role="img" aria-label="Hyprwise App Icon Dark">
  <rect width="1024" height="1024" rx="220" fill="#0C1210"/>
  <path fill="#FF6500" fill-rule="evenodd" d="${outerPath} ${innerPath}"/>
</svg>`;

export function getHyprwiseIconSvg(size: number = 32): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 1024 1024" role="img" aria-label="Hyprwise">
  <path fill="#FF6500" fill-rule="evenodd" d="${outerPath} ${innerPath}"/>
</svg>`;
}
