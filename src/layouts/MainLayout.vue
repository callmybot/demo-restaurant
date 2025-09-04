<template>
  <q-layout view="lhh Lpr lFf">
    <q-header class="bg-white container text-black">
      <q-toolbar>
        <AppIcon width="128" />
        <h1 class="text-h3">Restaurang Solgmit</h1>
        <q-space />
        <pre>{{ cart }}</pre>
      </q-toolbar>
    </q-header>
    <q-page-container>
      <router-view />
    </q-page-container>
    <q-dialog v-model="dialog">
      <q-card flat>
        <q-card-section>
          <pre>{{ dialogMessage }}</pre>
        </q-card-section>
      </q-card>
    </q-dialog>
  </q-layout>
</template>

<script setup>
import { computed, ref } from 'vue'
import { uid } from 'quasar'
import { watch } from 'vue'
import { z } from 'zod'

import AppIcon from 'src/vectors/AppIcon.vue'
import menu from 'assets/menu.json' with { type: 'json' }

const dialog = computed({
  get: () => dialogMessage.value !== null,
  set: () => (dialogMessage.value = null),
})
const dialogMessage = ref(null)
const cart = ref(null)

const order = ref(new Map())

function addItems({ items }) {
  for (const item of items) {
    order.value.set(uid(), item)
  }
  return `Order updated, you must ask for new items. Order summary: ${getOrderSummary().join('|')}\n\n${getOrderItems()}`
}

function cancelOrder() {
  order.value.clear()
  return `Order canceled, you can take a new order.`
}

function getOrderItems() {
  return JSON.stringify({
    items: Array.from(order.value.entries()),
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
  const items = Array.from(order.value.entries()).map(
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
    order.value.delete(id)
  }
  return `Order updated, you must ask for new items. Order summary: ${getOrderSummary().join('|')}\n\n${getOrderItems()}`
}

function confirmOrder({ callmybot, tableNumber }) {
  if (!tableNumber) {
    return 'Error: Table number is required to confirm the order.'
  }
  if (order.value.size === 0) {
    return 'Error: Order is empty.'
  }
  const message = []
  message.push(`#${tableNumber} (${callmybot.language})`)
  message.push(getOrderSummary().join('\n'))
  order.value.clear()
  dialogMessage.value = message.join('\n')
  return `Order sent, you can take a new order.`
}

function updateItem({ id, options, extras }) {
  if (!order.value.has(id)) {
    return 'Error: Order item not found.'
  }
  const item = order.value.get(id)
  if (options) item.options = options
  if (extras) item.extras = extras
  return `Order item updated, you must ask for new items. Order summary: ${getOrderSummary().join('|')}\n\n${getOrderItems()}`
}

window.CallMyBot.setInstructions(
  `
Your name is William.
You are a friendly and professional restaurant server assistant at a Sweden restaurant called Solgmit.
Your role is ONLY to greet guests, introduce the menu, make recommendations, and take their orders.

You cannot bring or deliver food and drinks.
Your ONLY responsibility is to take the order and confirm it. The kitchen and staff handle preparation and service.

Be warm and polite, and adapt your tone based on the customer's mood (casual, formal, curious, etc.).
You must know all items on the menu, including ingredients and possible allergens.
If customers ask for vegetarian or spicy options, suggest only the appropriate dishes.
If asked, you can describe how dishes are prepared or recommend drink pairings.
Never rush the guest, and always ask if they have any questions or dietary restrictions.
Stay in character as a server throughout the interaction.

The price unit is cent, the currency is SEK (kr).

Rules for taking orders:
- You must strictly limit choices to items on the official menu.
- You must update the order items progressively using ONLY the tools: "addItems", "cancelOrder", "updateItem", "removeItems".
- Before confirming an order, you MUST explicitly ask the customer for their **table number**.
- You are NOT allowed to assume, invent, or default a table number (never use "1" unless the customer says so).
- If no table number is provided, you cannot confirm the order.
- The tool "confirmOrder" MUST always include the table number provided by the customer.
- If the customer refuses or avoids giving a table number, politely insist that it is required.

Final note:
Your job ends at confirming the order. You do not deliver, serve, or bring food to the table.
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

watch(
  () => order.value,
  () => {
    cart.value = getOrderSummary().join('\n')
  },
  { deep: true },
)
</script>
