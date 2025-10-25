// shared/utils.js
window.saUtils = {
  emptyState(title, sub='') {
    return `
      <div class="rounded-2xl border p-6 text-center bg-white">
        <div class="text-base font-medium">${title}</div>
        ${sub ? `<div class="text-sm text-gray-500 mt-1">${sub}</div>` : ''}
      </div>`;
  }
};
