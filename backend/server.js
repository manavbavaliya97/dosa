const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Supabase client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// Initialize default menu items
const defaultMenuItems = [
  // 78 Dosa varieties
  { id: '1', name: 'Plain Dosa', price: 40, category: 'Dosa' },
  { id: '2', name: 'Crispy Plain Dosa', price: 45, category: 'Dosa' },
  { id: '3', name: 'Masala Dosa', price: 60, category: 'Dosa' },
  { id: '4', name: 'Crispy Masala Dosa', price: 65, category: 'Dosa' },
  { id: '5', name: 'Butter Masala Dosa', price: 70, category: 'Dosa' },
  { id: '6', name: 'Cheese Dosa', price: 80, category: 'Dosa' },
  { id: '7', name: 'Cheese Masala Dosa', price: 90, category: 'Dosa' },
  { id: '8', name: 'Cheese Onion Dosa', price: 85, category: 'Dosa' },
  { id: '9', name: 'Cheese Chilli Dosa', price: 95, category: 'Dosa' },
  { id: '10', name: 'Cheese Garlic Dosa', price: 95, category: 'Dosa' },
  { id: '11', name: 'Cheese Schezwan Dosa', price: 100, category: 'Dosa' },
  { id: '12', name: 'Onion Dosa', price: 50, category: 'Dosa' },
  { id: '13', name: 'Onion Masala Dosa', price: 65, category: 'Dosa' },
  { id: '14', name: 'Onion Chilli Dosa', price: 60, category: 'Dosa' },
  { id: '15', name: 'Rava Dosa', price: 55, category: 'Dosa' },
  { id: '16', name: 'Rava Masala Dosa', price: 70, category: 'Dosa' },
  { id: '17', name: 'Rava Onion Dosa', price: 65, category: 'Dosa' },
  { id: '18', name: 'Rava Cheese Dosa', price: 85, category: 'Dosa' },
  { id: '19', name: 'Mysore Masala Dosa', price: 75, category: 'Dosa' },
  { id: '20', name: 'Mysore Plain Dosa', price: 50, category: 'Dosa' },
  { id: '21', name: 'Paper Dosa', price: 50, category: 'Dosa' },
  { id: '22', name: 'Paper Masala Dosa', price: 70, category: 'Dosa' },
  { id: '23', name: 'Set Dosa (3 pcs)', price: 60, category: 'Dosa' },
  { id: '24', name: 'Kal Dosa', price: 45, category: 'Dosa' },
  { id: '25', name: 'Ghee Dosa', price: 65, category: 'Dosa' },
  { id: '26', name: 'Ghee Masala Dosa', price: 80, category: 'Dosa' },
  { id: '27', name: 'Ghee Onion Dosa', price: 75, category: 'Dosa' },
  { id: '28', name: 'Chutney Dosa', price: 50, category: 'Dosa' },
  { id: '29', name: 'Chutney Masala Dosa', price: 65, category: 'Dosa' },
  { id: '30', name: 'Pav Bhaji Dosa', price: 90, category: 'Dosa' },
  { id: '31', name: 'Pav Bhaji Masala Dosa', price: 100, category: 'Dosa' },
  { id: '32', name: 'Spring Roll Dosa', price: 95, category: 'Dosa' },
  { id: '33', name: 'Chinese Dosa', price: 85, category: 'Dosa' },
  { id: '34', name: 'Chinese Noodles Dosa', price: 95, category: 'Dosa' },
  { id: '35', name: 'Manchurian Dosa', price: 90, category: 'Dosa' },
  { id: '36', name: 'Schezwan Dosa', price: 70, category: 'Dosa' },
  { id: '37', name: 'Schezwan Masala Dosa', price: 85, category: 'Dosa' },
  { id: '38', name: 'Schezwan Cheese Dosa', price: 95, category: 'Dosa' },
  { id: '39', name: 'Chilli Dosa', price: 65, category: 'Dosa' },
  { id: '40', name: 'Chilli Cheese Dosa', price: 85, category: 'Dosa' },
  { id: '41', name: 'Podi Dosa', price: 50, category: 'Dosa' },
  { id: '42', name: 'Podi Masala Dosa', price: 65, category: 'Dosa' },
  { id: '43', name: 'Ghee Podi Dosa', price: 70, category: 'Dosa' },
  { id: '44', name: 'Palak Dosa', price: 60, category: 'Dosa' },
  { id: '45', name: 'Palak Masala Dosa', price: 75, category: 'Dosa' },
  { id: '46', name: 'Wheat Dosa', price: 50, category: 'Dosa' },
  { id: '47', name: 'Wheat Masala Dosa', price: 65, category: 'Dosa' },
  { id: '48', name: 'Adai Dosa', price: 55, category: 'Dosa' },
  { id: '49', name: 'Adai Masala Dosa', price: 70, category: 'Dosa' },
  { id: '50', name: 'Neer Dosa', price: 50, category: 'Dosa' },
  { id: '51', name: 'Paneer Dosa', price: 90, category: 'Dosa' },
  { id: '52', name: 'Paneer Masala Dosa', price: 100, category: 'Dosa' },
  { id: '53', name: 'Paneer Onion Dosa', price: 95, category: 'Dosa' },
  { id: '54', name: 'Paneer Cheese Dosa', price: 110, category: 'Dosa' },
  { id: '55', name: 'Paneer Butter Dosa', price: 105, category: 'Dosa' },
  { id: '56', name: 'Mushroom Dosa', price: 85, category: 'Dosa' },
  { id: '57', name: 'Mushroom Masala Dosa', price: 95, category: 'Dosa' },
  { id: '58', name: 'Mushroom Cheese Dosa', price: 105, category: 'Dosa' },
  { id: '59', name: 'Egg Dosa', price: 55, category: 'Dosa' },
  { id: '60', name: 'Double Egg Dosa', price: 70, category: 'Dosa' },
  { id: '61', name: 'Egg Masala Dosa', price: 75, category: 'Dosa' },
  { id: '62', name: 'Egg Onion Dosa', price: 70, category: 'Dosa' },
  { id: '63', name: 'Egg Cheese Dosa', price: 90, category: 'Dosa' },
  { id: '64', name: 'Vegetable Dosa', price: 70, category: 'Dosa' },
  { id: '65', name: 'Veg Masala Dosa', price: 80, category: 'Dosa' },
  { id: '66', name: 'Veg Cheese Dosa', price: 95, category: 'Dosa' },
  { id: '67', name: 'Masala Roast Dosa', price: 80, category: 'Dosa' },
  { id: '68', name: 'Tomato Dosa', price: 55, category: 'Dosa' },
  { id: '69', name: 'Tomato Masala Dosa', price: 70, category: 'Dosa' },
  { id: '70', name: 'Coconut Dosa', price: 60, category: 'Dosa' },
  { id: '71', name: 'Coconut Masala Dosa', price: 75, category: 'Dosa' },
  { id: '72', name: 'Gunpowder Dosa', price: 55, category: 'Dosa' },
  { id: '73', name: '70mm Dosa (Family)', price: 150, category: 'Dosa' },
  { id: '74', name: 'Jini Dosa', price: 95, category: 'Dosa' },
  { id: '75', name: 'Andhra Dosa', price: 65, category: 'Dosa' },
  { id: '76', name: 'Andhra Masala Dosa', price: 80, category: 'Dosa' },
  { id: '77', name: 'Keema Dosa', price: 120, category: 'Dosa' },
  { id: '78', name: 'Keema Masala Dosa', price: 130, category: 'Dosa' },
  // Breakfast
  { id: '79', name: 'Idli (2 pcs)', price: 30, category: 'Breakfast' },
  { id: '80', name: 'Idli (4 pcs)', price: 55, category: 'Breakfast' },
  { id: '81', name: 'Fried Idli', price: 40, category: 'Breakfast' },
  { id: '82', name: 'Vada (2 pcs)', price: 35, category: 'Breakfast' },
  { id: '83', name: 'Vada (4 pcs)', price: 65, category: 'Breakfast' },
  { id: '84', name: 'Sambar Vada', price: 45, category: 'Breakfast' },
  { id: '85', name: 'Dahi Vada', price: 50, category: 'Breakfast' },
  { id: '86', name: 'Pongal', price: 50, category: 'Breakfast' },
  { id: '87', name: 'Upma', price: 45, category: 'Breakfast' },
  { id: '88', name: 'Poori (3 pcs)', price: 55, category: 'Breakfast' },
  { id: '89', name: 'Poori Masala', price: 65, category: 'Breakfast' },
  { id: '90', name: 'Chapati (2 pcs)', price: 40, category: 'Breakfast' },
  { id: '91', name: 'Parotta (2 pcs)', price: 45, category: 'Breakfast' },
  { id: '92', name: 'Kothu Parotta', price: 75, category: 'Breakfast' },
  { id: '93', name: 'Chilli Parotta', price: 80, category: 'Breakfast' },
  { id: '94', name: 'Egg Parotta', price: 65, category: 'Breakfast' },
  { id: '95', name: 'Egg Kothu Parotta', price: 85, category: 'Breakfast' },
  // Uttapam
  { id: '96', name: 'Plain Uttapam', price: 45, category: 'Uttapam' },
  { id: '97', name: 'Onion Uttapam', price: 55, category: 'Uttapam' },
  { id: '98', name: 'Tomato Uttapam', price: 55, category: 'Uttapam' },
  { id: '99', name: 'Mixed Uttapam', price: 65, category: 'Uttapam' },
  { id: '100', name: 'Cheese Uttapam', price: 75, category: 'Uttapam' },
  { id: '101', name: 'Podi Uttapam', price: 50, category: 'Uttapam' },
  { id: '102', name: 'Ghee Onion Uttapam', price: 65, category: 'Uttapam' },
  // Beverages
  { id: '103', name: 'Tea', price: 15, category: 'Beverages' },
  { id: '104', name: 'Coffee', price: 20, category: 'Beverages' },
  { id: '105', name: 'Filter Coffee', price: 25, category: 'Beverages' },
  { id: '106', name: 'Cold Drink', price: 25, category: 'Beverages' },
  { id: '107', name: 'Water Bottle', price: 20, category: 'Beverages' },
  { id: '108', name: 'Lassi', price: 35, category: 'Beverages' },
  { id: '109', name: 'Buttermilk', price: 20, category: 'Beverages' },
  { id: '110', name: 'Fresh Juice', price: 40, category: 'Beverages' }
];

// Initialize default data
async function initializeData() {
  try {
    // Check if menu items exist
    const { data: existingItems, error: checkError } = await supabase
      .from('menu_items')
      .select('id')
      .limit(1);

    if (checkError) {
      console.error('Error checking menu items:', checkError);
      return;
    }

    if (!existingItems || existingItems.length === 0) {
      // Insert default menu items
      const { error: insertError } = await supabase
        .from('menu_items')
        .upsert(defaultMenuItems, { onConflict: 'id' });

      if (insertError) {
        console.error('Error inserting menu items:', insertError);
      } else {
        console.log('Default menu items added to Supabase');
      }
    }

    // Check/create app_config
    const { data: config, error: configError } = await supabase
      .from('app_config')
      .select('*')
      .limit(1);

    if (configError || !config || config.length === 0) {
      const { error: initConfigError } = await supabase
        .from('app_config')
        .upsert({
          id: '1',
          shop_name: 'Malhar Dosa',
          address: '',
          phone: '',
          gst_number: ''
        });

      if (initConfigError) {
        console.error('Error initializing app config:', initConfigError);
      }
    }
  } catch (err) {
    console.error('Error initializing data:', err);
  }
}

// API Routes

// Get all menu items
app.get('/api/menu', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('menu_items')
      .select('*');

    if (error) throw error;
    res.json(data || []);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get menu items by category
app.get('/api/menu/category/:category', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('menu_items')
      .select('*')
      .eq('category', req.params.category);

    if (error) throw error;
    res.json(data || []);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all categories
app.get('/api/categories', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('menu_items')
      .select('category');

    if (error) throw error;
    
    const categories = [...new Set((data || []).map(item => item.category))];
    res.json(categories.sort());
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Add new menu item
app.post('/api/menu', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('menu_items')
      .insert(req.body)
      .select()
      .single();

    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update menu item
app.put('/api/menu/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('menu_items')
      .update(req.body)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete menu item
app.delete('/api/menu/:id', async (req, res) => {
  try {
    const { error } = await supabase
      .from('menu_items')
      .delete()
      .eq('id', req.params.id);

    if (error) throw error;
    res.json({ message: 'Item deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Save order
app.post('/api/orders', async (req, res) => {
  try {
    const orderData = {
      order_id: req.body.orderId,
      items: req.body.items,
      subtotal: req.body.subtotal,
      tax_percent: req.body.taxPercent,
      tax_amount: req.body.taxAmount,
      discount: req.body.discount,
      total: req.body.total,
      created_at: req.body.createdAt || new Date().toISOString()
    };

    const { data, error } = await supabase
      .from('orders')
      .insert(orderData)
      .select()
      .single();

    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all orders
app.get('/api/orders', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('orders')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    res.json(data || []);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get today's orders
app.get('/api/orders/today', async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayStr = today.toISOString();

    const { data, error } = await supabase
      .from('orders')
      .select('*')
      .gte('created_at', todayStr)
      .order('created_at', { ascending: false });

    if (error) throw error;
    res.json(data || []);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get app config
app.get('/api/config', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('app_config')
      .select('*')
      .limit(1)
      .single();

    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update app config
app.put('/api/config', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('app_config')
      .upsert({ id: '1', ...req.body })
      .select()
      .single();

    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get printer config
app.get('/api/printer', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('printer_config')
      .select('*')
      .limit(1)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.json(null);
      }
      throw error;
    }
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Save printer config
app.put('/api/printer', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('printer_config')
      .upsert({ id: '1', ...req.body })
      .select()
      .single();

    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete printer config
app.delete('/api/printer', async (req, res) => {
  try {
    const { error } = await supabase
      .from('printer_config')
      .delete()
      .eq('id', '1');

    if (error) throw error;
    res.json({ message: 'Printer config cleared' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'malhar-pos-backend', database: 'supabase' });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);
  console.log('Connected to Supabase');
  await initializeData();
});
