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
    <q-dialog v-model="consoleDialoged">
      <q-card flat>
        <q-card-section>
          <pre>{{ consoleMessage }}</pre>
        </q-card-section>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup>
import { computed, ref } from 'vue'
import { uid } from 'quasar'
import { z } from 'zod'

import menu from 'assets/menu.json' with { type: 'json' }

const consoleDialoged = computed({
  get: () => consoleMessage.value !== null,
  set: () => (consoleMessage.value = null),
})
const consoleMessage = ref(null)

const order = new Map()

function addItems({ items }) {
  for (const item of items) {
    order.set(uid(), item)
  }
  return `Order updated, you must ask for new items. Order summary: ${getOrderSummary().join('|')}\n\n${getOrderItems()}`
}

function cancelOrder() {
  delete order.clear()
  return `Order canceled, you can take a new order.`
}

function getOrderItems() {
  return JSON.stringify({
    items: Array.from(order.entries()),
  })
}

function getItemDetails({ options, extras }) {
  const details = [
    ...(options ? options.map((option) => `${option.name}: ${option.choice}`) : []),
    ...(extras ? extras.map((extra) => `+ ${extra}`) : []),
  ]
  return details.length ? ` (${details.join(', ')})` : ''
}

function getOrderSummary() {
  const items = Array.from(order.entries()).map(
    ([, value]) => `${value.name}${getItemDetails(value)}`,
  )
  const counts = {}
  items.forEach((item) => {
    counts[item] = (counts[item] || 0) + 1
  })
  return Object.entries(counts)
    .sort((a, b) => b[1] - a[1])
    .map(([item, count]) => `${count} ${item}`)
}

function removeItems({ ids }) {
  for (const id of ids) {
    order.delete(id)
  }
  return `Order updated, you must ask for new items. Order summary: ${getOrderSummary().join('|')}\n\n${getOrderItems()}`
}

function confirmOrder({ callmybot, tableNumber }) {
  if (order.size === 0) {
    return 'Error: Order is empty.'
  }
  const message = []
  message.push(`#${tableNumber} (${callmybot.language})`)
  message.push(getOrderSummary().join('\n'))
  delete order.clear()
  consoleMessage.value = message.join('\n')
  return `Order sent, you can take a new order.`
}

function updateItem({ id, options, extras }) {
  if (!order.has(id)) {
    return 'Error: Order item not found.'
  }
  const item = order.get(id)
  if (options) item.options = options
  if (extras) item.extras = extras
  return `Order item updated, you must ask for new items. Order summary: ${getOrderSummary().join('|')}\n\n${getOrderItems()}`
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
You must update the order items progressively (addItems,cancelOrder,updateItem,removeItems).
You cannot bring but confirm the order by asking the table number (confirmOrder).
The price unit is cent, the currency is SEK (kr).
`,
)
  .setDatabase({ menu })
  .addTool(
    'addItems',
    {
      description: 'Add order items.',
      inputSchema: {
        items: z
          .array(
            z.object({
              name: z.string().describe('The item name.'),
              options: z
                .array(
                  z.object({
                    name: z.string().describe('The option name.'),
                    choice: z.string().describe('The option choice.'),
                  }),
                )
                .describe('The array of options.')
                .optional(),
              extras: z.array(z.string()).describe('The array of extra names.').optional(),
            }),
          )
          .describe('The array of order items.'),
      },
    },
    addItems,
  )
  .addTool(
    'cancelOrder',
    {
      description: 'Cancel the order.',
    },
    cancelOrder,
  )
  .addTool(
    'getOrderSummary',
    {
      description: 'Get the order summary.',
    },
    getOrderSummary,
  )
  .addTool(
    'removeItems',
    {
      description: 'Remove the order items.',
      inputSchema: {
        ids: z.array(z.string(), {
          description: 'The array of item identifiers.',
        }),
      },
    },
    removeItems,
  )
  .addTool(
    'confirmOrder',
    {
      description: 'Confirm the order.',
      inputSchema: {
        tableNumber: z.number().describe('The mandatory table number.'),
        callmybot: z.object({
          language: z.string(),
        }),
      },
    },
    confirmOrder,
  )
  .addTool(
    'updateItem',
    {
      description: 'Update order item.',
      inputSchema: {
        id: z.string().describe('The order item identifier.'),
        options: z
          .array(
            z.object({
              name: z.string().describe('The option name.'),
              choice: z.string().describe('The option choice.'),
            }),
          )
          .optional()
          .describe('The array of options.'),
        extras: z.array(z.string()).optional().describe('The array of extra names.'),
      },
    },
    updateItem,
  )

window.CallMyBot.onReady(() => {
  window.CallMyBot.open().sendSystemMessage('Introduce yourself.')
})
</script>
