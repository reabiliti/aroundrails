---
layout: post
title: "Guide Line for React"
date: "2020-02-10 23:29:18 +0300"
last_modified_at: "2020-02-10 23:29:18 +0300"
categories: react
---

### 1. Давайте использовать только arrow функции в JavaScript

В последнее время используются только arrow-functions для создания компонентов, так как они содержат меньше кода
и позволяют избежать некоторых проблем.

### 2. Файл компонента может содержать только один компонент
Если мы имеем компонент с в котором содержатся другие компонентыб то такой файл необходимо разбивать на отдельные
компоненты в разных файлах. Это помогает удобочитаемости кода.

### 3. Пример компонента.
```
/NameOfComponent
  name-of-component.scss // если необходима стилизация компонента.
  NameOfComponent.js
  index.js
```

Так же обязательно описываем свойства компонянта, какие типы должны приходить и обязательны
ли они. Если не обязательныб то необходимо указывать значения по умолчаниюб пример `NameOfComponent.js`:

{% highlight jsx%}

import React from 'react'
import { string } from 'prop-types'

import './name-of-component.scss' // если необходима стилизация компонента.

const NameOfComponent = ({ firstProp, secondProp }) => {

  return <div className='name-of-component'>
    <div className='name-of-component__first-class'>
      First paragraph
      {firstProp}
    </div>
    <div className='name-of-component__second-class'>
      Second paragraph
      {secondProp}
    </div>
  </div>
}

NameOfComponent.defaultProps = {
  secondProp: 'second'
}

NameOfComponent.propTypes = {
  firstProp: string.isRequired,
  secondProp: string
}

export default NameOfComponent

{% endhighlight %}

В файле index.js для удобства экспортируем компонент:

{% highlight jsx%}

import NameOfComponent from './NameOfComponent'

export default NameOfComponent

{% endhighlight %}

Файл стилей `name-of-component.scss`:

{% highlight scss%}

.name-of-component {
  width: 100%;
  font-size: 30px;

  .name-of-component__first-class {
    font-size: 20px;
  }

  .name-of-component__first-class {
    font-size: 10px;
  }
}

{% endhighlight %}

Если нам необходим какой-то кастомный компонент с логикой, который нигде больше
не будет использоваться, то можно его в этой же папке создать:

```
/NameOfComponent
  CustomComponent.js
  name-of-component.scss // если необходима стилизация компонента.
  NameOfComponent.js
  index.js
```

### 4. Стараться не использовать какую-то логику в jsx.

То есть имеется ввиду не разбовлять html в jsx какой-то логикой, на подобе прописывания
функции вычисления или в несколько рядов по onClick.

стоит избегать:

{% highlight jsx%}

import React, { useState } from 'react'
import { func, string } from 'prop-types'

import './name-of-component.scss' // если необходима стилизация компонента.

const NameOfComponent = ({ firstProp, secondProp, onClick }) => {
  const [state, setState] = useState(false)

  return <div className='name-of-component'>
    <div
      className='name-of-component__first-class'
      onClick={event => {
        event.preventDefault()
        setState(true)
        onClick()
      }}
    >
      First paragraph
      {firstProp}
    </div>
    <div className='name-of-component__second-class'>
      {state && <span>Second paragraph</span>}
      {secondProp}
    </div>
  </div>
}

NameOfComponent.defaultProps = {
  secondProp: 'second'
}

NameOfComponent.propTypes = {
  firstProp: string.isRequired,
  onClick: func.isRequired,
  secondProp: string
}

export default NameOfComponent

{% endhighlight %}

желательно делать:

{% highlight jsx%}

import React, { useState } from 'react'
import { func, string } from 'prop-types'

import './name-of-component.scss' // если необходима стилизация компонента.

const NameOfComponent = ({ firstProp, secondProp, onClick }) => {
  const [state, setState] = useState(false)
  const onClickNew = event => {
    event.preventDefault()
    setState(true)
    onClick()
  }

  return <div className='name-of-component'>
    <div className='name-of-component__first-class' onClick={onClickNew} >
      First paragraph
      {firstProp}
    </div>
    <div className='name-of-component__second-class'>
      {state && <span>Second paragraph</span>}
      {secondProp}
    </div>
  </div>
}

NameOfComponent.defaultProps = {
  secondProp: 'second'
}

NameOfComponent.propTypes = {
  firstProp: string.isRequired,
  onClick: func.isRequired,
  secondProp: string
}

export default NameOfComponent

{% endhighlight %}

или можно использовать useCallback, чтобы функция не пересоздавалась каждый рендер:

{% highlight jsx%}

import React, { useCallback, useState } from 'react'
import { func, string } from 'prop-types'

import './name-of-component.scss' // если необходима стилизация компонента.

const NameOfComponent = ({ firstProp, secondProp, onClick }) => {
  const [state, setState] = useState(false)
  const onClickNew = useCallback(event => {
    event.preventDefault()
    setState(true)
    onClick()
  }, [])

  return <div className='name-of-component'>
    <div className='name-of-component__first-class' onClick={onClickNew} >
      First paragraph
      {firstProp}
    </div>
    <div className='name-of-component__second-class'>
      {state && <span>Second paragraph</span>}
      {secondProp}
    </div>
  </div>
}

NameOfComponent.defaultProps = {
  secondProp: 'second'
}

NameOfComponent.propTypes = {
  firstProp: string.isRequired,
  onClick: func.isRequired,
  secondProp: string
}

export default NameOfComponent

{% endhighlight %}

### 5. Использовать линтер EsLint

Обязательно подключить линтер, так как он будет подсказывать, какие места лучше написать подругому,
так же может находить проблемные места в коде и импорте. Подсвечивает неиспользуемые переменные,
непоследовательный импорт (то есть вначале необходимо импортировать функции или компоненты из установленных пакетов,
а уже только потом созданные нами компоненты, хелперы, объекты или функции).

### 6. Импортировать и экспортировать функции или компоненты по алфавиту.

Для удобочитаемости предлагаю импортировать и экспортировать компоненты и функции по алфавиту, например:

{% highlight jsx%}

import React, { useState } from 'react' // Импортируется всегда первым
import { object } from 'prop-types' // Импортируется всегда вторым
import { Button, Dropdown } from 'react-bootstrap' // Далее идут по алфавиту компоненты из установленных пакетов

// После пропуска строки идут по алфавиту компоненты из созданных нами
import DeleteMenuItem from '../../../../atoms/MenuItems/DeleteMenuItem'
import DisabledMenuItem from '../../../../atoms/MenuItems/DisabledMenuItem'
import EditMenuItem from '../../../../atoms/MenuItems/EditMenuItem'

// После пропуска строки идут по алфавиту хелперы и функции созданные нами
import { clientDeleteButtonTooltip } from '../../../../../helpers/decorators/clientsDecorators'

// После пропуска строки идут по алфавиту константы (например константы роутов, но в данном компоненте они не используются)

// В конце через строку импортируем стили, если есть
import './client-addmin-cell.scss'

const ClientAdminCell = ({ column: { onEditClicked, onDeleteClicked }, row: { original } }) => {
  const [open, setOpen] = useState(false)

  const isUsedInProjects = original.projects.length > 0

  const onClickDelete = event => {
    if (!isUsedInProjects) {
      event.stopPropagation()
      setOpen(false)
      onDeleteClicked(original)
    }
  }

  const onClickEdit = event => {
    event.stopPropagation()
    setOpen(false)
    onEditClicked(original)
  }

  return (
    <Dropdown
      id={`dropdown-${original.uid}`}
      onClick={event => event.stopPropagation()}
      onToggle={opened => setOpen(opened)}
      pullRight
      open={open}
      className='client-admin-cell'
    >
      <Button bsRole='toggle' bsStyle='link' className='hamburger-button'>
        <i className='fas fa-ellipsis-h' />
      </Button>
      <Dropdown.Menu id={`dropdown-menu-${original.uid}`} bsRole='menu' open={open}>
        <EditMenuItem onClick={onClickEdit} />
        {!isUsedInProjects && <DeleteMenuItem onClick={onClickDelete} />}
        {isUsedInProjects && <DisabledMenuItem label='Delete' tooltipText={clientDeleteButtonTooltip(original)} />}
      </Dropdown.Menu>
    </Dropdown>
  )
}

ClientAdminCell.propTypes = {
  column: object.isRequired,
  row: object.isRequired
}

export default ClientAdminCell

{% endhighlight %}
