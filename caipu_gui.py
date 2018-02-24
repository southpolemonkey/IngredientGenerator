# author: chenxuan rong

import tkinter as tk
from tkinter.messagebox import showinfo
from tkinter import *
import psycopg2
import pandas as pd
from pandas import ExcelWriter
from pandas import ExcelFile


window = tk.Tk()
window.title('配菜清单生成器')
window.geometry('300x500')

var = tk.StringVar()
l = tk.Label(window, textvariable=var, bg='red', font=('Arial', 12), width=15,
             height=2)
#l = tk.Label(window, text='OMG! this is TK!', bg='green', font=('Arial', 12), width=15, height=2)
l.pack()

conn = psycopg2.connect(database = "caipu", user = "postgres", password = "postgres", host = "127.0.0.1", port = "5432")
cur = conn.cursor()


def conn_db():
	conn = psycopg2.connect(database = "caipu", user = "postgres", password = "postgres", host = "127.0.0.1", port = "5432")
	var.set("数据库连接成功")
	cur = conn.cursor()


def test():
	t = tk.Toplevel()
	t.wm_title("test")
	t.geometry("300x400")

	Label(t, text='日期').grid(row=0)
	Label(t, text='标题').grid(row=1)

	e1 = Entry(t)
	e2 = Entry(t)

	e1.grid(row=0, column=1)
	e2.grid(row=1, column=1)

	button1 = Button(t, text='提交', width=10,height=2)
	button2 = Button(t, text='取消', width=10,height=2)
	button1.grid(row=2, column=0)
	button2.grid(row=2, column=1)


def create_menu():
	var.set("新建菜单")
	windows1 = tk.Toplevel()
	windows1.wm_title("新建菜单")
	windows1.geometry("300x400")

	all_entries = []
	all_option = []

	def add_box(kind):

		cur.execute("SELECT name FROM t_c where catergory = %s", str(kind))
		name_list = cur.fetchall()

		cai_var = StringVar(windows1)
		cai_var.set(name_list[0])

		cai = OptionMenu(windows1, cai_var, *name_list)
		cai.grid()

		all_entries.append(cai_var)
		all_option.append(cai)

	def yes():
		input_date = cr1.get()
		input_title = cr2.get()
		excel = []
		excel.append(input_date)
		excel.append(input_title)

		try:
		    cur.execute("INSERT INTO history(menu_date, title) VALUES(%s, %s)",(input_date, input_title))
		    conn.commit()
		except psycopg2.DatabaseError as e:
			showinfo('Error', '数据库操作错误')

		# 读取Optionmenu的菜名
		cai = []
		for ent in all_entries:
			b = ent.get()[2:-3]
			cai.append(b)

		# 查询菜谱
		cur.callproc('get_ingredient',(cai,))
		rows = cur.fetchall()

		# 写入excel文件
		shopping_list_name = input_date + "_" + input_title
		for row in rows:
			# shopping_list.write(row[0] + "\n")
			excel.append(row[0])

		df = pd.DataFrame({'配料':excel})
		writer = ExcelWriter(shopping_list_name + '.xlsx')
		df.to_excel(writer, 'Sheet1', index=False)
		writer.save()

		showinfo('window','创建菜单成功！')


	def no():
		cr1.delete(0,'end')
		cr2.delete(0,'end')

	button1 = Button(windows1, text='提交', width=8, height=2,command=yes)
	button2 = Button(windows1, text='取消', width=8, height=2,command=no)
	button1.grid(row=0, column=0)
	button2.grid(row=0, column=1)

	Label(windows1, text='日期').grid(row=1)
	Label(windows1, text='标题').grid(row=2)

	cr1 = Entry(windows1)
	cr2 = Entry(windows1)

	cr1.grid(row=1, column=1)
	cr2.grid(row=2, column=1)


	# 增加菜名 四种按钮
	addbox1 = tk.Button(windows1, text="荤菜", width=8, command=lambda: add_box(1))
	addbox1.grid(row=3,column=0)
	addbox2 = tk.Button(windows1, text="冷菜", width=8, command=lambda: add_box(2))
	addbox2.grid(row=3,column=1)
	addbox3 = tk.Button(windows1, text="点心", width=8, command=lambda: add_box(3))
	addbox3.grid(row=4,column=0)
	addbox4 = tk.Button(windows1, text="汤类", width=8, command=lambda: add_box(4))
	addbox4.grid(row=4,column=1)


def query():
    windows2 = tk.Toplevel()
    windows2.wm_title("查询菜谱")
    windows2.geometry("300x400")

    def output():
    	cai = []
    	item = input_column.get()
    	cai.append(item)
    	print(cai)
    	cur.callproc('get_ingredient',(cai,))
    	rows = cur.fetchall()
    	for row in rows:
    		t.insert('insert', row[0] + "\n")

    def no():
    	input_column.delete(0,'end')
    	t.delete(1.0,'end')

    # Entry输入菜名后，在Text中显示结果
    display = tk.Label(windows2, text="请输入菜名", font=('Arial', 12), width=15, height=2)
    display.pack() 

    input_column = tk.Entry(windows2)
    input_column.pack()

    ## 摁下确认按钮，讲用户输入值传递给查询函数
    confirm = tk.Button(windows2, text="确认", width=10,height=2,command=output)
    confirm.pack()

    no = tk.Button(windows2, text='清空', width=10, height=2,command=no)
    no.pack()

    t = tk.Text(windows2, font=('Arial', 12), height=10)
    t.pack()


def add_dish():
	var.set("增加菜式")
	windows3 = tk.Toplevel()
	windows3.wm_title("增加菜式")
	windows3.geometry("300x400")

	def yes():
		name = in1.get()
		material = in2.get()
		material_list = material.split(" ")
		kind = in3.get()
		cur.execute("SELECT * FROM add_ingredient(%s,%s,%s);",(name,kind,material_list))
		conn.commit()
		row = cur.fetchone()
		print(row[0])
		if row[0]:
			showinfo("window","操作成功!")
		else:
			showinfo("window","菜名已存在!")

	def no():
		in1.delete(0, 'end')
		in2.delete(0, 'end')
		in3.delete(0, 'end')

    # 输入菜名
	dp_name = tk.Label(windows3, text='菜名', font=('Arial', 12), width=15, height=2)
	dp_name.pack()

	in1 = tk.Entry(windows3)
	in1.pack()

    # 配料
	dp_list = tk.Label(windows3, text='配料(用空格隔开)', font=('Arial', 12), width=15, height=2)
	dp_list.pack()

	in2 = tk.Entry(windows3)
	in2.pack()
    
    # 类别
	dp_kind = tk.Label(windows3, text='类别(1:荤菜 2:素菜 3:点心 4:汤类)', font=('Arial', 12), width=30, height=2)
	dp_kind.pack()

	in3 = tk.Entry(windows3)
	in3.pack()

	y = tk.Button(windows3, text="确认", width=10,height=2,command=yes)
	y.pack()
	n = tk.Button(windows3, text="取消", width=10,height=2,command=no)
	n.pack()

def history_order():
    windows4 = tk.Tk()
    windows4.title("历史订单")
    windows4.geometry("300x400")

    display4 = tk.Label(windows4, text="所有清单", font=('Arial', 12), width=15, height=2)
    display4.pack() 

    t4 = tk.Text(windows4,height=15)

    cur.execute("SELECT * FROM history ORDER BY menu_date")
    rows = cur.fetchall()
    for row in rows:
    	t4.insert('insert', str(row[1])+":"+row[2] + "\n")

    t4.pack()


b1 = tk.Button(window, text='连接数据库', width=15,
              height=2, command=conn_db)
b1.pack()

b2 = tk.Button(window, text='新建菜单', width=15,
              height=2, command=create_menu)
b2.pack()

b3 = tk.Button(window, text='查询菜谱', width=15,
              height=2, command=query)
b3.pack()

b4 = tk.Button(window, text='增加菜式', width=15,
              height=2, command=add_dish)
b4.pack()

b5 = tk.Button(window, text='历史订单', width=15,
              height=2, command=history_order)
b5.pack()

b6 = tk.Button(window, text='测试', width=15,
              height=2, command=test)
b6.pack()

window.mainloop()