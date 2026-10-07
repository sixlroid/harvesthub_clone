(() => {
  const formStates = new WeakMap();
  const getFormFields = (form) => form.querySelectorAll(
    'input:not([type="hidden"]):not([type="button"]):not([type="submit"]):not([type="reset"]):not([type="image"]), select, textarea'
  );

  const getSubmitButtons = (form) => form.querySelectorAll(
    'button[type="submit"], button:not([type]), input[type="submit"], input[type="image"]'
  );

  const updateResetButton = (form) => {
    const state = formStates.get(form);
    if (!state || state.resetting) return;

    state.resetButton.disabled = !Array.from(getFormFields(form)).some((field) => {
      if (field.type === 'checkbox' || field.type === 'radio') return field.checked;
      if (field.type === 'file') return field.files.length > 0;
      if (field.tagName === 'SELECT') {
        return field.multiple
          ? field.selectedOptions.length > 0
          : field.selectedIndex >= 0 && field.value !== '';
      }
      return field.value.trim() !== '';
    });
  };

  const addResetButton = (form) => {
    if (formStates.has(form)) return;

    const submitButton = getSubmitButtons(form)[0];
    const actionContainer = submitButton?.closest('.form-actions, .claim-modal-actions');
    let actions = actionContainer;

    if (!actions) {
      actions = document.createElement('div');
      const isInline = getComputedStyle(form).display === 'flex'
        && getComputedStyle(form).flexDirection !== 'column';
      actions.className = `form-actions${isInline ? ' form-actions-inline' : ''}`;

      if (submitButton) {
        submitButton.parentNode.insertBefore(actions, submitButton);
        actions.appendChild(submitButton);
      } else {
        form.appendChild(actions);
      }
    }

    const resetButton = document.createElement('button');
    resetButton.type = 'button';
    resetButton.textContent = 'Reset';
    resetButton.className = `btn form-reset-button ${
      submitButton?.classList.contains('btn-light') ? 'btn-light' : 'btn-ghost'
    }${submitButton?.classList.contains('btn-sm') ? ' btn-sm' : ''}`;
    resetButton.disabled = true;

    if (submitButton) {
      actions.insertBefore(resetButton, submitButton);
    } else {
      actions.appendChild(resetButton);
    }

    const state = {
      resetButton,
      resetting: false
    };
    formStates.set(form, state);

    resetButton.addEventListener('click', () => {
      state.resetting = true;

      getFormFields(form).forEach((field) => {
        if (field.type === 'checkbox' || field.type === 'radio') {
          field.checked = false;
        } else if (field.type === 'file') {
          field.value = '';
        } else if (field.tagName === 'SELECT') {
          Array.from(field.options).forEach((option) => { option.selected = false; });
          field.selectedIndex = -1;
        } else {
          field.value = '';
        }

        const eventName = field.tagName === 'SELECT'
          || field.type === 'checkbox'
          || field.type === 'radio'
          || field.type === 'file'
          ? 'change'
          : 'input';
        field.dispatchEvent(new Event(eventName, { bubbles: true }));
      });

      resetButton.disabled = true;
      state.resetting = false;
      updateForm(form);
    });
  };

  const isMissingRequiredField = (field) => {
    if (!field.willValidate) return false;
    if (field.type === 'checkbox' || field.type === 'radio' || field.tagName === 'SELECT') {
      return field.validity.valueMissing;
    }
    return field.value.trim() === '';
  };

  const hasMissingRequiredFields = (form) => {
    const requiredFields = form.querySelectorAll('input[required], select[required], textarea[required]');
    return Array.from(requiredFields).some(isMissingRequiredField);
  };

  const updateForm = (form) => {
    addResetButton(form);
    const missingRequiredFields = hasMissingRequiredFields(form);

    getSubmitButtons(form).forEach((button) => {
      if (missingRequiredFields) {
        if (!button.disabled) {
          button.dataset.requiredFieldsDisabled = 'true';
          button.disabled = true;
        }
      } else if (button.dataset.requiredFieldsDisabled === 'true') {
        button.disabled = false;
        delete button.dataset.requiredFieldsDisabled;
      }
    });
    updateResetButton(form);
  };

  const updateAllForms = () => {
    document.querySelectorAll('form').forEach(updateForm);
  };

  document.addEventListener('input', (event) => {
    if (event.target.form && !formStates.get(event.target.form)?.resetting) {
      updateForm(event.target.form);
    }
  });

  document.addEventListener('change', (event) => {
    if (event.target.form && !formStates.get(event.target.form)?.resetting) {
      updateForm(event.target.form);
    }
  });

  document.addEventListener('reset', (event) => {
    setTimeout(() => updateForm(event.target), 0);
  });

  document.addEventListener('submit', (event) => {
    if (!hasMissingRequiredFields(event.target)) {
      getSubmitButtons(event.target).forEach((button) => {
        delete button.dataset.requiredFieldsDisabled;
      });
      return;
    }

    event.preventDefault();
    event.stopImmediatePropagation();
    updateForm(event.target);
    Array.from(event.target.querySelectorAll('input[required], select[required], textarea[required]'))
      .find((field) => isMissingRequiredField(field))
      ?.focus();
  }, true);

  const observer = new MutationObserver((mutations) => {
    const forms = new Set();

    mutations.forEach((mutation) => {
      if (mutation.type === 'childList') {
        if (mutation.target.form) {
          forms.add(mutation.target.form);
        }
        mutation.addedNodes.forEach((node) => {
          if (node.nodeType !== Node.ELEMENT_NODE) return;
          if (node.matches('form')) forms.add(node);
          node.querySelectorAll('form').forEach((form) => forms.add(form));
          if (node.form) forms.add(node.form);
          node.querySelectorAll('input[required], select[required], textarea[required]')
            .forEach((field) => {
              if (field.form) forms.add(field.form);
            });
        });
      } else if (mutation.target.form) {
        forms.add(mutation.target.form);
      }
    });

    forms.forEach(updateForm);
  });

  updateAllForms();
  observer.observe(document.body, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ['required']
  });

  window.addEventListener('load', () => setTimeout(updateAllForms, 300));
})();
