import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(home: MyVideoPage()));

class MyVideoPage extends StatefulWidget {
  @override
  State<MyVideoPage> createState() => _MyVideoPageState();
}

class _MyVideoPageState extends State<MyVideoPage> with SingleTickerProviderStateMixin {
  // late TabController _tabController;

  final List<String> tabs = ['All', 'Camera', 'Download', 'WhatsApp Video'];

  @override
  void initState() {
    super.initState();
    // _tabController = TabController(length: tabs.length, vsync: this);
  }
  @override
  void dispose() {
    // _tabController?.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        body: NestedScrollView(
          
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              backgroundColor: Colors.amber,
              title: Text("Videos"),
              floating: true,
              pinned: true,
              snap: true,
              actions: [
                IconButton(icon: Icon(Icons.search), onPressed: () {}),
                IconButton(icon: Icon(Icons.grid_view), onPressed: () {}),
              ],
              bottom: TabBar(
                // controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: Colors.orange,
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                tabs: tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
          ],
          body: TabBarView(
            // controller: _tabController,
            children: tabs.map((tab) {
              return ListView.builder(
                padding: EdgeInsets.all(10),
                itemCount: 20,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.play_circle_outline),
                    title: Text("$tab Video ${index + 1}"),
                    subtitle: Text("Date: 24 June · Size: ${(20 + index) % 100} MB"),
                    trailing: Icon(Icons.more_vert),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}





// class MyVideoUI extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Videos"),
//         actions: [
//           IconButton(onPressed: () {}, icon: Icon(Icons.search)),
//           IconButton(onPressed: () {}, icon: Icon(Icons.grid_view)),
//         ],
//       ),
//       body: NestedScrollView(
//         floatHeaderSlivers: true,
//         headerSliverBuilder: (context, innerBoxIsScrolled) {
//           return [
//             SliverToBoxAdapter(
//               child: Container(
//                 color: Colors.amber.shade100,
//                 padding: EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Custom Header Container",
//                       style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       "This header scrolls out and comes back in!",
//                       style: TextStyle(fontSize: 16),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ];
//         },
//         body: ListView.builder(
//           padding: EdgeInsets.all(10),
//           itemCount: 30,
//           itemBuilder: (context, index) {
//             return Card(
//               margin: EdgeInsets.only(bottom: 10),
//               child: ListTile(
//                 leading: Icon(Icons.video_collection),
//                 title: Text("Video ${index + 1}"),
//                 subtitle: Text("Size: ${(index + 1) * 5} MB"),
//                 trailing: Icon(Icons.more_vert),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
