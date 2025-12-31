
import 'package:flutter/material.dart';
import 'package:mess_management/fund/clear_fund.dart';
import 'package:mess_management/fund/fand_list.dart';
import 'package:mess_management/fund/fund_entry.dart';


class FundScreen extends StatefulWidget {
  const FundScreen({super.key});

  @override
  State<FundScreen> createState() => _FundScreenState();
}


// class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
//   final TabBar _tabBar;

//   _SliverTabBarDelegate(this._tabBar);

//   @override
//   double get minExtent => _tabBar.preferredSize.height;
//   @override
//   double get maxExtent => _tabBar.preferredSize.height;

//   @override
//   Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
//     return Container(
//       color: Colors.white, // Optional: background color
//       child: _tabBar,
//     );
//   }

//   @override
//   bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
// }

class _FundScreenState extends State<FundScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  final List<String> tabs =const ['Fund Tnx List', 'Add Fund', 'Clear Fand'];
  final List<Icon> icons =const [Icon(Icons.list_alt),Icon(Icons.create),Icon(Icons.clear),];


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, scrollable){
          return [
            SliverAppBar(
              backgroundColor: Colors.grey,
              title: AnimatedBuilder(
                animation: _tabController!,
                builder: (context, child) {
                  return Text(tabs[_tabController!.index]);
                },
              ),
              actions: [],
              floating: true,
              snap: true,
              pinned: true,
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,// must assign otherwise get an error
                tabAlignment: TabAlignment.start,
                labelColor: Colors.black,
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelColor: Colors.black,
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
                indicatorColor: Colors.black,
                tabs:tabs.map((e)=> Tab(text: e.toString() , icon:icons[tabs.indexOf(e)],)).toList(),
              ),
            ),
            
          ];
        },
        
        body:TabBarView(
          controller: _tabController,
          children: [
            FundList(),
            AddFund(),
            ClearFund(),
          ],
        )
      ),
    );
  }
}



