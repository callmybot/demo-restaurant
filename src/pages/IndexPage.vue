<template>
  <q-page padding class="container">
    <section :key="category" v-for="(products, category) in menu">
      <h2 class="text-h4">{{ category }}</h2>
      <div class="row q-col-gutter-lg">
        <div :key="index" v-for="(product, index) in products" class="col-12 col-md-6">
          <q-card flat>
            <q-card-section>
              <div class="text-h6">{{ product.name }} – {{ product.price / 100 }} kr</div>
            </q-card-section>

            <q-card-section v-if="product.description || product.allergens">
              <div class="text-subtitle1">{{ product.description }}</div>
              <div v-if="product.allergens" class="text-caption">
                Allergener: {{ product.allergens.join(', ') }}
              </div>
            </q-card-section>
          </q-card>
        </div>
      </div>
    </section>
    <q-dialog v-model="console">
      <q-card flat>
        <q-card-section>
          <pre>{{ consoleMessage }}</pre>
        </q-card-section>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup>
import { uid } from 'quasar'
import { computed, ref } from 'vue'

import menu from 'assets/menu.json' with { type: 'json' }

const console = computed({
  get: () => consoleMessage.value !== null,
  set: () => (consoleMessage.value = null),
})
const consoleMessage = ref(null)

const order = new Map()

function add_items(items) {
  for (const item of items) {
    order.set(uid(), item)
  }
  return `Order updated, you must ask for new items. Order summary: ${get_order_summary().join('|')}\n\n${get_order_items()}`
}

function cancel_order() {
  delete order.clear()
  return `Order canceled, you can take a new order.`
}

function get_order_items() {
  return JSON.stringify({
    items: Array.from(order.entries()),
  })
}

function get_item_details(options, extras) {
  const details = [
    ...(options ? options.map((option) => `${option.name}: ${option.choice}`) : []),
    ...(extras ? extras.map((extra) => `+ ${extra}`) : []),
  ]
  return details.length ? ` (${details.join(', ')})` : ''
}

function get_order_summary() {
  const items = Array.from(order.entries()).map(
    ([, value]) => `${value.name}${get_item_details(value.options, value.extras)}`,
  )
  const counts = {}
  items.forEach((item) => {
    counts[item] = (counts[item] || 0) + 1
  })
  return Object.entries(counts)
    .sort((a, b) => b[1] - a[1])
    .map(([item, count]) => `${count} ${item}`)
}

function remove_items(ids) {
  for (const id of ids) {
    order.delete(id)
  }
  return `Order updated, you must ask for new items. Order summary: ${get_order_summary().join('|')}\n\n${get_order_items()}`
}

function submit_order(language, table) {
  if (order.size === 0) {
    return 'Error: Order is empty.'
  }
  const message = []
  message.push(`#${table} (${language})`)
  message.push(get_order_summary().join('\n'))
  delete order.clear()
  consoleMessage.value = message.join('\n')
  return `Order sent, you can take a new order.`
}

function update_item(id, options, extras) {
  if (!order.has(id)) {
    return 'Error: Order item not found.'
  }
  const item = order.get(id)
  if (options) item.options = options
  if (extras) item.extras = extras
  return `Order item updated, you must ask for new items. Order summary: ${get_order_summary().join('|')}\n\n${get_order_items()}`
}

window.CallMyBot.setInstructions(
  `
Your name is William.
You are a friendly and professional restaurant translator at a Sweden restaurant called Solgmit.
Your job is to greet guests, introduce the menu, make recommendations based on their preferences, and take their orders.
Be warm and polite, and adapt your tone based on the customer's mood (casual, formal, curious, etc.).
You should be familiar with all items on the menu, including ingredients and possible allergens.
If customers ask for vegetarian or spicy options, suggest appropriate dishes.
If asked, you can describe how dishes are prepared or recommend drink pairings.
Never rush the guest, and always ask if they have any questions or dietary restrictions.
Stay in character as a server throughout the interaction.
You must strictly limit the choices according to the restaurant's menu.
You must update the order items progressively.
You must confirm the order before sending it.
The price unit is cent, the currency is SEK (kr).
`,
)
  .setDatabase({ menu })
  .addFunction(
    'add_items',
    'Add order items.',
    {
      type: 'object',
      properties: {
        items: {
          type: 'array',
          description: 'The array of order items.',
          items: {
            type: 'object',
            properties: {
              name: {
                type: 'string',
                description: 'The item name.',
              },
              options: {
                type: 'array',
                description: 'The array of options.',
                items: {
                  type: 'object',
                  properties: {
                    name: {
                      type: 'string',
                      description: 'The option name.',
                    },
                    choice: {
                      type: 'string',
                      description: 'The option choice.',
                    },
                  },
                  required: ['name', 'choice'],
                },
              },
              extras: {
                type: 'array',
                description: 'The array of extra names.',
                items: {
                  type: 'string',
                },
              },
            },
            additionalProperties: false,
            required: ['name'],
          },
        },
      },
    },
    add_items,
  )
  .addFunction(
    'cancel_order',
    'Cancel the order.',
    {
      type: 'object',
      properties: {},
    },
    cancel_order,
  )
  .addFunction(
    'get_order_summary',
    'Get the order summary.',
    {
      type: 'object',
      properties: {},
    },
    get_order_summary,
  )
  .addFunction(
    'remove_items',
    'Remove the order items.',
    {
      type: 'object',
      properties: {
        ids: {
          type: 'array',
          description: 'The array of item identifiers.',
          items: {
            type: 'string',
          },
        },
      },
      additionalProperties: false,
      required: ['ids'],
    },
    remove_items,
  )
  .addFunction(
    'submit_order',
    'Bring, send or validate the order after confirmation.',
    {
      type: 'object',
      properties: {
        table: {
          type: 'integer',
          description: 'The mandatory table number.',
        },
      },
      additionalProperties: false,
      required: ['table'],
    },
    submit_order,
  )
  .addFunction(
    'update_item',
    'Update order item.',
    {
      type: 'object',
      properties: {
        id: {
          type: 'string',
          description: 'The order item identifier.',
        },
        options: {
          type: 'array',
          description: 'The array of options.',
          items: {
            type: 'object',
            properties: {
              name: {
                type: 'string',
                description: 'The option name.',
              },
              choice: {
                type: 'string',
                description: 'The option choice.',
              },
            },
            required: ['name', 'choice'],
          },
        },
        extras: {
          type: 'array',
          description: 'The array of extra names.',
          items: {
            type: 'string',
          },
        },
      },
      additionalProperties: false,
      required: ['id'],
    },
    update_item,
  )

window.CallMyBot.onReady(() => {
  window.CallMyBot.open().sendSystemMessage('Introduce yourself.')
})
</script>
